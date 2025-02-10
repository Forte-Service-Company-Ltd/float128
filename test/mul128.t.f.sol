/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/float128.sol";
import "test/FloatPythonUtils.sol";

contract Mul128FuzzTest is FloatPythonUtils {
    function testStruct_mul(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -128, 127);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -128, 127);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));
        console2.log("Before mul");

        Float memory result = Float128.mul(Float({significand: aMan, exponent: aExp}), Float({significand: bMan, exponent: bExp}));
        //resSol = resSol * 10 >> resExp;
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        console2.log("solRes: ", result.significand);
        console2.log("solRes: ", result.exponent);
        assertEq(pyMan, result.significand);
        assertEq(pyExp, result.exponent);
    }

    function testEncoded_mul(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -128, 127);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -128, 127);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));
        console2.log("Before mul");

        float128 a = Float128.encode(aMan, aExp);
        float128 b = Float128.encode(bMan, bExp);

        float128 result = Float128.mul(a, b);
        console2.log("result: ", float128.unwrap(result));
        (int rMan, int rExp) = Float128.decode(result);
        //resSol = resSol * 10 >> resExp;
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        console2.log("solRes: ", rMan);
        console2.log("solRes: ", rExp);
        assertEq(pyMan, rMan);
        assertEq(pyExp, rExp);
    }

    function testStruct_divl(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -128, 127);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -128, 127);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        Float memory result = Float128.div(Float({significand: aMan, exponent: aExp}), Float({significand: bMan, exponent: bExp}));
        //resSol = resSol * 10 >> resExp;
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        console2.log("solRes: ", result.significand);
        console2.log("solRes: ", result.exponent);
        assertEq(pyMan, result.significand);
        assertEq(pyExp, result.exponent);
    }
}
