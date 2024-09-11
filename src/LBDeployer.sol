// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {LBFactory} from "./LBFactory.sol";
import {LBPair} from "./LBPair.sol";

contract LBDeployer {
    LBFactory public factory;

    LBPair public pair;

    constructor(
        address feeRecipient,
        address owner,
        uint256 flashLoanFee,
        uint16[] memory binSteps,
        uint16[] memory baseFactors,
        uint16[] memory filterPeriods,
        uint16[] memory decayPeriods,
        uint16[] memory reductionFactors,
        uint24[] memory variableFeeControls,
        uint16[] memory protocolShares,
        uint24[] memory maxVolatilityAccumulators
    ) {
        factory = new LBFactory(
            feeRecipient,
            address(this),
            flashLoanFee
        );

        pair = new LBPair(factory);

        factory.setLBPairImplementation(address(pair));

        for (uint256 i = 0; i < binSteps.length; i++) {
            factory.setPreset(
                binSteps[i],
                baseFactors[i],
                filterPeriods[i],
                decayPeriods[i],
                reductionFactors[i],
                variableFeeControls[i],
                protocolShares[i],
                maxVolatilityAccumulators[i],
                true
            );
        }

        factory.transferOwnership(owner);
    }
}