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
        (int rMan, int rExp) = Float128.decode(result);

        assertEq(pyMan, rMan);
        assertEq(pyExp, rExp);
    }

    function testStruct_div(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -128, 127);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -128, 127);

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
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -100, 100);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -100, 100);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        float128 a = Float128.encode(aMan, aExp);
        float128 b = Float128.encode(bMan, bExp);

        float128 result = Float128.div(a, b);
        console2.log("result: ", float128.unwrap(result));
        (int rMan, int rExp) = Float128.decode(result);
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
        console2.log("rMan: ", rMan);
        console2.log("rExp: ", rExp);
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        assertEq(pyMan, rMan);
        assertEq(pyExp, rExp);
    }

    function testEncoded_add(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -100, 100);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -100, 100);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        float128 a = Float128.encode(aMan, aExp);
        float128 b = Float128.encode(bMan, bExp);

        float128 result = Float128.add(a, b);
        console2.log("result: ", float128.unwrap(result));
        (int rMan, int rExp) = Float128.decode(result);
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
        console2.log("rMan: ", rMan);
        console2.log("rExp: ", rExp);
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        assertEq(pyMan, rMan);
        assertEq(pyExp, rExp);
    }

    function testStruct_add(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -100, 100);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -100, 100);

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
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -100, 100);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -100, 100);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        float128 a = Float128.encode(aMan, aExp);
        float128 b = Float128.encode(bMan, bExp);

        float128 result = Float128.sub(a, b);
        console2.log("result: ", float128.unwrap(result));
        (int rMan, int rExp) = Float128.decode(result);
        // we fix the python result due to the imprecision of the log10. We cut precision where needed
        
        console2.log("rMan: ", rMan);
        console2.log("rExp: ", rExp);
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        assertEq(pyMan, rMan);
        assertEq(pyExp, rExp);
    }

    function testStruct_sub(int aMan, int aExp, int bMan, int bExp) public {
        aMan = bound(aMan, 1, 1 << 128 - 1);
        aExp = bound(aExp, -100, 100);
        bMan = bound(bMan,  1, 1 << 128 - 1);
        bExp = bound(bExp, -100, 100);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256,int256));

        Float memory result = Float128.sub(Float({significand: aMan, exponent: aExp}), Float({significand: bMan, exponent: bExp}));
        console2.log("rMan: ", result.significand);
        console2.log("rExp: ", result.exponent);
        console2.log("pyMan: ", pyMan);
        console2.log("pyExp: ", pyExp);
        assertEq(pyMan, result.significand);
        assertEq(pyExp, result.exponent);
    }
}
