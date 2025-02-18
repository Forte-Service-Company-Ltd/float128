// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {GasHelpers} from "test/GasHelpers.sol";
import "lib/forge-std/src/console2.sol";
import {Float, packedFloat, Float128} from "src/Float128.sol";

contract GasReport is Test, GasHelpers {
    using Float128 for Float;

    function testGasUsedStructs_add() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -26, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.add(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("struct: ", gasUsed);
    }

    function testGasUsedStructs_sub() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -26, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.sub(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("struct: ", gasUsed);
    }

    function testGasUsedStructs_mul() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -26, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.mul(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("struct: ", gasUsed);
    }

    function testGasUsedStructs_div() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});
        Float memory B = Float({exponent: -36, mantissa: int(33678000000000000000000000000000000000)});
        startMeasuringGas("Gas used - structs");
        Float128.div(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("struct: ", gasUsed);
    }

    function testGasUsedStructs_sqrt() public {
        _primer();
        uint256 gasUsed = 0;

        Float memory A = Float({exponent: -36, mantissa: int(22345000000000000000000000000000000000)});

        startMeasuringGas("Gas used - sqrt128");
        Float128.sqrt(A);

        gasUsed = stopMeasuringGas();
        console2.log("add: ", gasUsed);
    }

    function testGasUsedUints() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        // packedFloat a = packedFloat.wrap(_a);
        // packedFloat b = packedFloat.wrap(_b);

        startMeasuringGas("Gas used - uints");
        Float128.add(a, b);
        gasUsed = stopMeasuringGas();
        console2.log("2 uints: ", gasUsed);
    }

    function testGasUsedLog10() public {
        _primer();
        uint256 gasUsed = 0;

        uint256 x = type(uint208).max;
        startMeasuringGas("Gas used - log10");

        Float128.findNumberOfDigits(x);
        gasUsed = stopMeasuringGas();
        console2.log("log10: ", gasUsed);
    }

    function testGasUsedEncoded_mul() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - mul128");
        Float128.mul(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("mul128: ", gasUsed);
    }

    function testGasUsedEncoded_div() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - div128");
        Float128.div(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("div128: ", gasUsed);
    }

    function testGasUsedEncoded_sub() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - sub128");
        Float128.sub(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("sub: ", gasUsed);
    }

    function testGasUsedEncoded_add() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);
        packedFloat b = Float128.toPackedFloat(33678000000000000000000000000000000000, -36);

        startMeasuringGas("Gas used - add128");
        Float128.add(a, b);

        gasUsed = stopMeasuringGas();
        console2.log("add: ", gasUsed);
    }

    function testGasUsedEncoded_sqrt() public {
        _primer();
        uint256 gasUsed = 0;

        packedFloat a = Float128.toPackedFloat(22345000000000000000000000000000000000, -26);

        startMeasuringGas("Gas used - sqrt128");
        Float128.sqrt(a);

        gasUsed = stopMeasuringGas();
        console2.log("add: ", gasUsed);
    }
}
