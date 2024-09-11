// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "./helpers/TestHelper.sol";

import {LBDeployer} from "../src/LBDeployer.sol";
import {LBFactory} from "../src/LBFactory.sol";
import {LBPair} from "../src/LBPair.sol";

contract LBDeployerTest is TestHelper {
    function test_OwnerIsTransfered() public {
        uint16[] memory emptyUint16 = new uint16[](0);
        uint24[] memory emptyUint24 = new uint24[](0);

        LBDeployer deployer = new LBDeployer(
            DEV,
            DEV,
            DEFAULT_FLASHLOAN_FEE,
            emptyUint16,
            emptyUint16,
            emptyUint16,
            emptyUint16,
            emptyUint16,
            emptyUint24,
            emptyUint16,
            emptyUint24
        );

        LBFactory factory = deployer.factory();

        assertEq(factory.pendingOwner(), DEV, "test_OwnerIsTransfered::1");

        vm.prank(DEV);
        factory.acceptOwnership();

        assertEq(factory.owner(), DEV, "test_OwnerIsTransfered::2");
    }

    function test_CreateLBPair() public {
        uint16[] memory uint16Array = new uint16[](1);
        uint16Array[0] = 1;
        uint24[] memory uint24Array = new uint24[](1);
        uint24Array[0] = 1;

        LBDeployer deployer = new LBDeployer(
            DEV,
            DEV,
            DEFAULT_FLASHLOAN_FEE,
            uint16Array,
            uint16Array,
            uint16Array,
            uint16Array,
            uint16Array,
            uint24Array,
            uint16Array,
            uint24Array
        );

        LBFactory factory = deployer.factory();

        ILBPair pair = factory.createLBPair(usdt, usdc, ID_ONE, 1);

        assertEq(factory.getNumberOfLBPairs(), 1, "test_CreateLBPair::1");

        LBFactory.LBPairInformation memory pairInfo = factory.getLBPairInformation(usdt, usdc, 1);
        assertEq(pairInfo.binStep, 1, "test_CreateLBPair::2");
        assertEq(address(pairInfo.LBPair), address(pair), "test_CreateLBPair::3");
        assertFalse(pairInfo.createdByOwner, "test_CreateLBPair::4");
        assertFalse(pairInfo.ignoredForRouting, "test_CreateLBPair::5");

        assertEq(factory.getAllLBPairs(usdt, usdc).length, 1, "test_CreateLBPair::6");
        assertEq(address(factory.getAllLBPairs(usdt, usdc)[0].LBPair), address(pair), "test_CreateLBPair::7");

        assertEq(address(pair.getFactory()), address(factory), "test_CreateLBPair::8");
        assertEq(address(pair.getTokenX()), address(usdt), "test_CreateLBPair::9");
        assertEq(address(pair.getTokenY()), address(usdc), "test_CreateLBPair::10");
    }

    function test_PairImplementation() public {
        uint16[] memory emptyUint16 = new uint16[](0);
        uint24[] memory emptyUint24 = new uint24[](0);

        LBDeployer deployer = new LBDeployer(
            DEV,
            DEV,
            DEFAULT_FLASHLOAN_FEE,
            emptyUint16,
            emptyUint16,
            emptyUint16,
            emptyUint16,
            emptyUint16,
            emptyUint24,
            emptyUint16,
            emptyUint24
        );

        LBFactory factory = deployer.factory();
        LBPair pair = deployer.pair();

        assertEq(
            address(factory.getLBPairImplementation()),
            address(pair),
            "test_PairImplementation::1"
        );

        assertEq(
            address(pair.getFactory()),
            address(factory),
            "test_PairImplementation::2"
        );
    }

    function testFuzz_SetPreset_1(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor
    ) public {
        LBDeployer deployer;

        binStep = uint16(bound(binStep, factory.getMinBinStep(), type(uint16).max));
        filterPeriod = uint16(bound(filterPeriod, 0, Encoded.MASK_UINT12 - 1));
        decayPeriod = uint16(bound(decayPeriod, filterPeriod + 1, Encoded.MASK_UINT12));
        reductionFactor = uint16(bound(reductionFactor, 0, Constants.BASIS_POINT_MAX));

        {
            uint16[] memory binSteps = new uint16[](1);
            uint16[] memory baseFactors = new uint16[](1);
            uint16[] memory filterPeriods = new uint16[](1);
            uint16[] memory decayPeriods = new uint16[](1);
            uint16[] memory reductionFactors = new uint16[](1);
            uint24[] memory variableFeeControls = new uint24[](1);
            uint16[] memory protocolShares = new uint16[](1);
            uint24[] memory maxVolatilityAccumulators = new uint24[](1);

            binSteps[0] = binStep;
            baseFactors[0] = baseFactor;
            filterPeriods[0] = filterPeriod;
            decayPeriods[0] = decayPeriod;
            reductionFactors[0] = reductionFactor;

            deployer = new LBDeployer(
                DEV,
                DEV,
                DEFAULT_FLASHLOAN_FEE,
                binSteps,
                baseFactors,
                filterPeriods,
                decayPeriods,
                reductionFactors,
                variableFeeControls,
                protocolShares,
                maxVolatilityAccumulators
            );
        }

        LBFactory factory = deployer.factory();

        assertEq(factory.getAllBinSteps().length, 1, "testFuzz_SetPreset::4");
        assertEq(factory.getAllBinSteps()[0], binStep, "testFuzz_SetPreset::5");

        {
            (uint256 baseFactorView, uint256 filterPeriodView, uint256 decayPeriodView, uint256 reductionFactorView,,,,)
            = factory.getPreset(binStep);

            assertEq(baseFactorView, baseFactor, "testFuzz_SetPreset::6");
            assertEq(filterPeriodView, filterPeriod, "testFuzz_SetPreset::7");
            assertEq(decayPeriodView, decayPeriod, "testFuzz_SetPreset::8");
            assertEq(reductionFactorView, reductionFactor, "testFuzz_SetPreset::9");
        }
    }

    function testFuzz_SetPreset_2(
        uint16 binStep,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) public {
        LBDeployer deployer;

        binStep = uint16(bound(binStep, factory.getMinBinStep(), type(uint16).max));
        variableFeeControl = uint24(bound(variableFeeControl, 0, Constants.BASIS_POINT_MAX));
        protocolShare = uint16(bound(protocolShare, 0, 2_500));
        maxVolatilityAccumulator = uint24(bound(maxVolatilityAccumulator, 0, Encoded.MASK_UINT20));

        {
            uint16[] memory binSteps = new uint16[](1);
            uint16[] memory baseFactors = new uint16[](1);
            uint16[] memory filterPeriods = new uint16[](1);
            uint16[] memory decayPeriods = new uint16[](1);
            uint16[] memory reductionFactors = new uint16[](1);
            uint24[] memory variableFeeControls = new uint24[](1);
            uint16[] memory protocolShares = new uint16[](1);
            uint24[] memory maxVolatilityAccumulators = new uint24[](1);

            binSteps[0] = binStep;
            decayPeriods[0] = 1;
            variableFeeControls[0] = variableFeeControl;
            protocolShares[0] = protocolShare;
            maxVolatilityAccumulators[0] = maxVolatilityAccumulator;

            deployer = new LBDeployer(
                DEV,
                DEV,
                DEFAULT_FLASHLOAN_FEE,
                binSteps,
                baseFactors,
                filterPeriods,
                decayPeriods,
                reductionFactors,
                variableFeeControls,
                protocolShares,
                maxVolatilityAccumulators
            );
        }

        LBFactory factory = deployer.factory();

        assertEq(factory.getAllBinSteps().length, 1, "testFuzz_SetPreset::4");
        assertEq(factory.getAllBinSteps()[0], binStep, "testFuzz_SetPreset::5");

        {
            (
                ,
                ,
                ,
                ,
                uint256 variableFeeControlView,
                uint256 protocolShareView,
                uint256 maxVolatilityAccumulatorView,
            ) = factory.getPreset(binStep);

            assertEq(variableFeeControlView, variableFeeControl, "testFuzz_SetPreset::10");
            assertEq(protocolShareView, protocolShare, "testFuzz_SetPreset::11");
            assertEq(maxVolatilityAccumulatorView, maxVolatilityAccumulator, "testFuzz_SetPreset::12");
        }
    }
}