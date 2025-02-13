/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import "test/FloatPythonUtils.sol";

contract Mul128FuzzTest is FloatPythonUtils {

    function setBounds(int aMan, int aExp, int bMan, int bExp) internal pure returns(int _aMan, int _aExp, int _bMan, int _bExp){
        // numbers with more than 38 digits lose precision
        _aMan = bound(aMan, -99999999999999999999999999999999999999, 99999999999999999999999999999999999999);
        _aExp = bound(aExp, -74, 74);
        _bMan = bound(bMan,  -99999999999999999999999999999999999999, 99999999999999999999999999999999999999);
        _bExp = bound(bExp, -74, 74);
    }
    function testStruct_mul(int aMan, int aExp, int bMan, int bExp) public  {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        console2.log("aMan: ", aMan);
        console2.log("aExp: ", aExp);
        console2.log("bMan: ", bMan);
        console2.log("bExp: ", bExp);
        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));
        console2.log("Before mul");

        Float memory result = Float128.mul(Float({significand: aMan, exponent: aExp}), Float({significand: bMan, exponent: bExp}));

        assertEq(pyMan, result.significand);
        assertEq(pyExp, result.exponent);
    }

    function testEncoded_mul(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));
        console2.log("Before mul");

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.mul(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        if(pyMan != 0)
            assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1: rMan)), 38, "Solidity result is not normalized");
        if(pyExp != rExp){
            if(pyExp > rExp){
                ++rExp;
                rMan /= 10;
            }else{
                ++pyExp;
                pyMan /= 10;
            }
        }

        assertEq(pyMan, rMan);
        if(pyMan != 0) assertEq(pyExp, rExp);
    }

    function testStruct_div(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        if (bMan == 0) bMan = 1;

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        Float memory result = Float128.div(Float({significand: aMan, exponent: aExp}), Float({significand: bMan, exponent: bExp}));
        // we fix the python result due to the imprecision of the log10. We cut precision where needed
        if(pyExp != result.exponent){
            if(pyExp > result.exponent){
                ++result.exponent;
                result.significand /= 10;
            }else{
                ++pyExp;
                pyMan /= 10;
            }
        }
        assertEq(pyMan, result.significand);
        assertEq(pyExp, result.exponent);
    }

    function testEncoded_div(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.div(a, b);
        console2.log("result: ", packedFloat.unwrap(result));
        (int rMan, int rExp) = Float128.decode(result);

        assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1: rMan)), 38, "Solidity result is not normalized");
        // we fix the python result due to the imprecision of the log10. We cut precision where needed
        if(pyExp != rExp){
            if(pyExp > rExp){
                ++rExp;
                rMan /= 10;
            }else{
                ++pyExp;
                pyMan /= 10;
            }
        }
        assertEq(pyMan, rMan);
        assertEq(pyExp, rExp);
    }

    function testEncoded_add(int aMan, int aExp, int bMan, int bExp) public {
        // it loses precision when numbers have more than 38 digits
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.add(a, b);
        console2.log("result: ", packedFloat.unwrap(result));
        (int rMan, int rExp) = Float128.decode(result);

        assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1: rMan)), 38, "Solidity result is not normalized");
        // we fix the python result due to the imprecision of the log10. We cut precision where needed
        if(pyExp != rExp){
            if(pyExp > rExp){
                ++rExp;
                rMan /= 10;
            }else{
                ++pyExp;
                pyMan /= 10;
            }
        }
        // we could be off by one due to rounding issues. The error should be less than 1/1e76
        if (pyMan != rMan){
            if(pyMan > rMan) assertEq(pyMan , rMan + 1);
            else assertEq(pyMan + 1, rMan);
        }
        assertEq(pyExp, rExp);
    }

    function testStruct_add(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        Float memory result = Float128.add(Float({significand: aMan, exponent: aExp}), Float({significand: bMan, exponent: bExp}));
        console2.log("rMan: ", result.significand);
        console2.log("rExp: ", result.exponent);
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        assertEq(pyMan, result.significand);
        assertEq(pyExp, result.exponent);
    }

    function testEncoded_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        aMan = -99999999999999999999999999999999999996;
        aExp = -66;
        bMan = 0;
        bExp = 63; 


        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.sub(a, b);
        console2.log("result: ", packedFloat.unwrap(result));
        (int rMan, int rExp) = Float128.decode(result);

        assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1: rMan)), 38, "Solidity result is not normalized");
        // we fix the python result due to the imprecision of the log10. We cut precision where needed
        if(pyExp != rExp){
            if(pyExp > rExp){
                ++rExp;
                rMan /= 10;
            }else{
                ++pyExp;
                pyMan /= 10;
            }
        }
        // we could be off by one due to rounding issues. The error should be less than 1/1e76
        if (pyMan != rMan){
            if(pyMan > rMan) assertEq(pyMan , rMan + 1);
            else assertEq(pyMan + 1, rMan);
        }
        assertEq(pyExp, rExp);
    }

    function testStruct_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        Float memory result = Float128.sub(Float({significand: aMan, exponent: aExp}), Float({significand: bMan, exponent: bExp}));
        console2.log("rMan: ", result.significand);
        console2.log("rExp: ", result.exponent);
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        if (pyMan != result.significand){
            if(pyMan > result.significand) assertEq(pyMan + 1, result.significand);
            else assertEq(pyMan, result.significand + 1);
        }
        assertEq(pyExp, result.exponent);
    }

    function findNumberOfDigits(uint x) internal pure returns (uint log) {
        assembly {
            if gt(x, 0) {
                if gt(
                    x,
                    9999999999999999999999999999999999999999999999999999999999999999
                ) {
                    log := 64
                    x := div(
                        x,
                        10000000000000000000000000000000000000000000000000000000000000000
                    )
                }
                if gt(x, 99999999999999999999999999999999) {
                    log := add(log, 32)
                    x := div(x, 100000000000000000000000000000000)
                }
                if gt(x, 9999999999999999) {
                    log := add(log, 16)
                    x := div(x, 10000000000000000)
                }
                if gt(x, 99999999) {
                    log := add(log, 8)
                    x := div(x, 100000000)
                }
                if gt(x, 9999) {
                    log := add(log, 4)
                    x := div(x, 10000)
                }
                if gt(x, 99) {
                    log := add(log, 2)
                    x := div(x, 100)
                }
                if gt(x, 9) {
                    log := add(log, 1)
                }
                log := add(log, 1)
            }
        }
    }
}

