// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {GasHelpers} from "test/GasHelpers.sol";
import "lib/forge-std/src/console2.sol";
import {Float2Ints, FloatStructLibSol, Float, FloatUintLib, float128} from "src/float128.sol";

contract GasReport is Test, GasHelpers {
    using Float2Ints for int256;
    using FloatStructLibSol for Float;
    //

    function testGasUsedStructs() public {
        _primer();
        uint256 gasUsed = 0;

        //setAStructs(22345000000000000000000000000000000000);
        //setBStructs(33678000000000000000000000000000000000);
        Float memory A = Float({
            exponent: -36,
            significand: int(22345000000000000000000000000000000000)
        });
        Float memory B = Float({
            exponent: -36,
            significand: int(33678000000000000000000000000000000000)
        });

        startMeasuringGas("Gas used - structs");
        FloatStructLibSol.addStructs(A, B);

        gasUsed = stopMeasuringGas();
        console2.log("struct: ", gasUsed);
    }

    function testGasUsedInts() public {
        _primer();
        uint256 gasUsed = 0;

        //setAInts(22345000000000000000000000000000000000, -36);
        //setBInts(33678000000000000000000000000000000000, -36);
        int a = 22345000000000000000000000000000000000;
        int b = 33678000000000000000000000000000000000;

        startMeasuringGas("Gas used - ints");

        Float2Ints.addInts(a, -36, b, -36);

        gasUsed = stopMeasuringGas();
        console2.log("2 ints: ", gasUsed);
    }

    function testGasUsedUints() public {
        _primer();
        uint256 gasUsed = 0;

        //setAInts(22345000000000000000000000000000000000, -36);
        //setBInts(33678000000000000000000000000000000000, -36);
        /*float128 a = float128(
            0x000000000000000000000000000000b8195625990e78ddb46cd69d8c00000000
        );
        float128 b = float128(
            0x000000000000000000000000000000b810cf7d8ed5a96744e5135bda00000000
        );*/
        uint256 a = FloatUintLib.encode(
            22345000000000000000000000000000000000,
            -36
        );
        uint256 b = FloatUintLib.encode(
            33678000000000000000000000000000000000,
            -36
        );

        startMeasuringGas("Gas used - uints");

        FloatUintLib.addUints(a, b);
        gasUsed = stopMeasuringGas();
        console2.log("2 uints: ", gasUsed);
    }

    function testGasUsedLog10() public {
        _primer();
        uint256 gasUsed = 0;

        uint256 x = type(uint208).max;
        startMeasuringGas("Gas used - log10");

        FloatUintLib.log10Ceiling(x);
        gasUsed = stopMeasuringGas();
        console2.log("log10: ", gasUsed);
    }

    function testGasUsedMul128() public {
        _primer();
        uint256 gasUsed = 0;

        startMeasuringGas("Gas used - mul128");
        Float2Ints.mul128(
            22345000000000000000000000000000000000,
            -36,
            33678000000000000000000000000000000000,
            -36
        );

        gasUsed = stopMeasuringGas();
        console2.log("mul128: ", gasUsed);
    }
}
