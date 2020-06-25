pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

contract CatalystDataBase {
    event CatalystConfiguration(uint256 indexed id, uint16 minQuantity, uint16 maxQuantity, uint256 sandMintingFee, uint256 sandUpdateFee);

    function _setData(uint256 id, CatalystData memory data) internal {
        _data[id] = data;
        _emitConfiguration(id, data.minQuantity, data.maxQuantity, data.sandMintingFee, data.sandUpdateFee);
    }

    function _setConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        _data[id].minQuantity = minQuantity;
        _data[id].maxQuantity = maxQuantity;
        _data[id].sandMintingFee = uint88(sandMintingFee);
        _data[id].sandUpdateFee = uint88(sandUpdateFee);
        _emitConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    function _emitConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        emit CatalystConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    function getValue(
        uint256 catalystId,
        uint256 seed,
        uint32 gemId,
        bytes32 blockHash,
        uint256 slotIndex
    ) external view returns (uint32) {
        uint16 minValue = _data[catalystId].minValue;
        uint16 maxValue = _data[catalystId].maxValue;

        return _computeValue(seed, gemId, minValue, maxValue, blockHash, slotIndex);
    }

    function _computeValue(
        uint256 seed,
        uint32 gemId,
        uint16 minValue,
        uint16 maxValue,
        bytes32 blockHash,
        uint256 slotIndex
    ) internal pure returns (uint32) {
        uint16 range = maxValue - minValue;
        return minValue + uint16(uint256(keccak256(abi.encodePacked(gemId, seed, blockHash, slotIndex))) % range);
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        uint32[] calldata gemIds,
        bytes32[] calldata blockHashes,
        uint256 startIndex
    ) external view returns (uint32[] memory values) {
        require(gemIds.length == blockHashes.length, "inconsisten length");
        uint16 minValue = _data[catalystId].minValue;
        uint16 maxValue = _data[catalystId].maxValue;
        values = new uint32[](gemIds.length);
        for (uint256 i = 0; i < gemIds.length; i++) {
            values[i] = _computeValue(seed, gemIds[i], minValue, maxValue, blockHashes[i], startIndex + i);
        }
    }

    function getMintData(uint256 catalystId)
        external
        view
        returns (
            uint16 maxGems,
            uint16 minQuantity,
            uint16 maxQuantity,
            uint256 sandMintingFee,
            uint256 sandUpdateFee
        )
    {
        maxGems = _data[catalystId].maxGems;
        minQuantity = _data[catalystId].minQuantity;
        maxQuantity = _data[catalystId].maxQuantity;
        sandMintingFee = _data[catalystId].sandMintingFee;
        sandUpdateFee = _data[catalystId].sandUpdateFee;
    }

    struct CatalystData {
        uint88 sandMintingFee;
        uint88 sandUpdateFee;
        uint16 minQuantity;
        uint16 maxQuantity;
        uint16 minValue;
        uint16 maxValue;
        uint16 maxGems;
    }

    mapping(uint256 => CatalystData) _data;
}