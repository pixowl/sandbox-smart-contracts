const {guard} = require('../lib');
const {getLands} = require('../data/landPreSale_2/getLands');

module.exports = async ({getNamedAccounts, deployments, network}) => {
    const {deployIfDifferent, deploy, log, getChainId} = deployments;
    const chainId = await getChainId();

    const {
        deployer,
        landSaleBeneficiary,
    } = await getNamedAccounts();

    const sandContract = await deployments.get('Sand');
    const landContract = await deployments.get('Land');

    if (!sandContract) {
        throw new Error('no SAND contract deployed');
    }

    if (!landContract) {
        throw new Error('no LAND contract deployed');
    }

    let daiMedianizer = await deployments.get('DAIMedianizer');
    if (!daiMedianizer) {
        log('setting up a fake DAI medianizer');
        const daiMedianizerDeployResult = await deploy(
            'DAIMedianizer',
            {from: deployer, gas: 6721975},
            'FakeMedianizer',
        );
        daiMedianizer = daiMedianizerDeployResult.contract;
    }

    let dai = await deployments.get('DAI');
    if (!dai) {
        log('setting up a fake DAI');
        const daiDeployResult = await deploy(
            'DAI', {
                from: deployer,
                gas: 6721975,
            },
            'FakeDai',
        );
        dai = daiDeployResult.contract;
    }

    const {lands, merkleRootHash} = getLands(network.live, chainId);

    const deployResult = await deployIfDifferent(['data'],
        'LandPreSale_2',
        {from: deployer, gas: 1000000, linkedData: lands},
        'LandSaleWithETHAndDAI',
        landContract.address,
        sandContract.address,
        sandContract.address,
        deployer,
        landSaleBeneficiary,
        merkleRootHash,
        1582718400, // 1582718400 converts to Tuesday February 26, 2020 09:00:00 (am) in time zone America/Argentina/Buenos Aires (-03)
        daiMedianizer.address,
        dai.address
    );
    const contract = await deployments.get('LandPreSale_2');
    if (deployResult.newlyDeployed) {
        log(' - LandPreSale_2 deployed at : ' + contract.address + ' for gas : ' + deployResult.receipt.gasUsed);
    } else {
        log('reusing LandPreSale_2 at ' + contract.address);
    }
};
module.exports.skip = guard(['1', '4', '314159'], 'LandPreSale_2');