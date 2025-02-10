// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;
import "forge-std/console2.sol";

type float128 is uint256;

struct Float {
    int significand;
    int exponent;
}

library Float128{
    /**  
    * Bitmap:
    * 255 ... UNUSED ... 138, 137 ... EXPONENT ... 129, MANTISSA_SIGN (128), 127 .. MANTISSA ... 0
    * The exponent is signed using the offset zero to 128. max values: -128 and +127. Plenty for our case
    **/
    uint constant MANTISSA_MASK = 0xffffffffffffffffffffffffffffffff;
    uint constant MANTISSA_SIGN_MASK = 0x100000000000000000000000000000000;
    uint constant EXPONENT_MASK = 0xfffffffffffffffffffffffffffffffe00000000000000000000000000000000;
    uint constant TOW_COMPLEMENT_SIGN_MASK = 0x8000000000000000000000000000000000000000000000000000000000000000;
    uint constant BASE = 10;
    uint constant ZERO_OFFSET = 256;
    uint constant ZERO_OFFSET_MINUS_1 = 255;
    uint constant EXPONENT_BIT = 129;
    uint constant MAX_DIGITS = 38;
    uint constant MAX_DIGITS_X_2 = 76;

    function add(float128 a, float128 b) internal pure returns (float128 r) {
        assembly {
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            // we adjust the significant digits and set the exponent of the result
            if gt(aExp, bExp) {
                r := aExp
                bMan := div(bMan, exp(BASE, sub(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp))))
            }
            if gt(bExp, aExp) {
                r := bExp
                aMan := div(aMan, exp(BASE, sub(shr(EXPONENT_BIT, bExp), shr(EXPONENT_BIT, aExp))))
            }
            if eq(aExp, bExp) {
                r := aExp
            }
            /// we use complements 2 for mantissa sign
            if and(a, MANTISSA_SIGN_MASK) {
                aMan := add(not(aMan), 1)
            }
            if and(b, MANTISSA_SIGN_MASK) {
                bMan := add(not(bMan), 1)
            }
            let addition := add(aMan, bMan)
            if and(TOW_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := add(not(addition), 1) // convert back from 2's complement
            }
            r := or(r, addition)
        }
    }

    function sub(float128 a, float128 b) internal pure returns (float128 r) {
        assembly {
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            // we adjust the significant digits and set the exponent of the result
            if gt(aExp, bExp) {
                r := aExp
                bMan := div(bMan, exp(BASE, sub(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp))))
            }
            if gt(bExp, aExp) {
                r := bExp
                aMan := div(aMan, exp(BASE, sub(shr(EXPONENT_BIT, bExp), shr(EXPONENT_BIT, aExp))))
            }
            if eq(aExp, bExp) {
                r := aExp
            }
            /// we use complements 2 for mantissas sign
            if and(a, MANTISSA_SIGN_MASK) {
                aMan := add(not(aMan), 1)
            }
            /// we invert the sign for b to do a subtraction instead of an addition
            if xor(b, MANTISSA_SIGN_MASK) {
                bMan := add(not(bMan), 1)
            }
            let addition := add(aMan, bMan)
            if and(TOW_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := add(not(addition), 1) // convert back from 2's complement
            }
            r := or(r, addition)
        }
    }

    function mul(float128 a, float128 b) internal pure returns (float128 r) {

        console2.log("a", float128.unwrap(a));
        console2.log("b", float128.unwrap(b));
        uint rMan;
        uint rExp;
        assembly {
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            ///
            rMan := mul(aMan, bMan)
            rExp := sub(add(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp)), ZERO_OFFSET)
        }
        uint256 rawResultSize = findNumberOfDigits(rMan);
        console2.log("rawResultSize", rawResultSize);
        assembly {
            if gt(rawResultSize, MAX_DIGITS) {
                let expReducer := sub(rawResultSize, MAX_DIGITS)
                rMan := div(rMan, exp(BASE, expReducer))
                rExp := add(rExp, expReducer)
            }
            r :=  or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)),or(rMan,shl(EXPONENT_BIT, rExp)))
        }
    }

    function div(float128 a, float128 b) internal pure returns(float128 r){
        uint rMan;
        uint rExp;
        uint aMan; 
        uint aExp;
        assembly{
            aMan := and(a, MANTISSA_MASK)
            aExp := and(a, EXPONENT_MASK)
        }
        uint digitsA = findNumberOfDigits(aMan);
        assembly{
            let bMan := and(b, MANTISSA_MASK)
            let expMultiplier := sub(MAX_DIGITS_X_2, digitsA)
            aMan := mul(aMan, exp(BASE, expMultiplier))
            aExp := sub(aExp,  expMultiplier)
            rMan := div(aMan, bMan)
        }
        console2.log("aExp", aExp);
        uint rawResultSize = findNumberOfDigits(rMan);
        assembly{
            let bExp := and(b, EXPONENT_MASK)
            let expReducer := sub(rawResultSize, MAX_DIGITS)
            rExp := sub(add(add(aExp, ZERO_OFFSET), expReducer), bExp)
            rMan := div(rMan, exp(BASE, expReducer))
            r :=  or(xor(and(a, MANTISSA_SIGN_MASK), and(b, MANTISSA_SIGN_MASK)),or(rMan,shl(EXPONENT_BIT, rExp)))
        }
    }
    

    function encode(
        int mantissa,
        int exponent
    ) internal pure returns (float128 float) {
        // bounds not enforced yet
        assembly {
            if and(mantissa, TOW_COMPLEMENT_SIGN_MASK) {
                float := or(MANTISSA_SIGN_MASK, add(not(mantissa), 1))
            }
            if iszero(and(mantissa, TOW_COMPLEMENT_SIGN_MASK)) {
                float := mantissa
            }
            float := or(float, shl(EXPONENT_BIT, add(exponent, ZERO_OFFSET)))
        }
    }

    function decode(
        float128 float
    ) internal pure returns (int mantissa, int exponent) {
        assembly {
            // exponent
            let _exp := shr(EXPONENT_BIT, float)
            if gt(ZERO_OFFSET, _exp) {
                exponent := add(not(sub(ZERO_OFFSET, _exp)), 1)
            }
            if gt(_exp, ZERO_OFFSET_MINUS_1) {
                exponent := sub(_exp, ZERO_OFFSET)
            }
            // mantissa
            mantissa := and(float, MANTISSA_MASK)
            /// we use complements 2 for mantissa sign
            if and(float, MANTISSA_SIGN_MASK) {
                mantissa := add(not(mantissa), 1)
            }
        }
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

    function add(
        Float memory a,
        Float memory b
    ) internal pure returns (Float memory r) {
        assembly {
            if eq(mload(add(a, 0x20)), mload(add(b, 0x20))) {
                mstore(add(r, 0x20), mload(add(a, 0x20)))
                mstore(r, add(mload(a), mload(b)))
            }
            if gt(mload(add(a, 0x20)), mload(add(b, 0x20))) {
                mstore(add(r, 0x20), mload(add(a, 0x20)))
                mstore(
                    r,
                    add(
                        mload(a),
                        div(
                            mload(b),
                            exp(
                                10,
                                add(
                                    mload(add(a, 0x20)),
                                    add(not(mload(add(b, 0x20))), 1)
                                )
                            )
                        )
                    )
                )
            }
            if gt(mload(add(b, 0x20)), mload(add(a, 0x20))) {
                mstore(add(r, 0x20), mload(add(b, 0x20)))
                mstore(
                    r,
                    add(
                        mload(b),
                        div(
                            mload(a),
                            exp(
                                10,
                                add(
                                    mload(add(b, 0x20)),
                                    add(not(mload(add(a, 0x20))), 1)
                                )
                            )
                        )
                    )
                )
            }
        }
    }

    function sub(Float memory a, Float memory b) internal pure returns (Float memory r) {
        assembly {
            /// we negate the sign of b to do subtraction instead of addition
            mstore(b, add(not(mload(add(b, 0x20))), 1))
            /// we perform regular addition 
            if eq(mload(add(a, 0x20)), mload(add(b, 0x20))) {
                mstore(add(r, 0x20), mload(add(a, 0x20)))
                mstore(r, add(mload(a), mload(b)))
            }
            if gt(mload(add(a, 0x20)), mload(add(b, 0x20))) {
                mstore(add(r, 0x20), mload(add(a, 0x20)))
                mstore(r, add(
                    mload(a),
                    div(mload(b), exp(10, add(mload(add(a, 0x20)), add(not(mload(add(b, 0x20))), 1)))))
                )
            }
            if gt(mload(add(b, 0x20)), mload(add(a, 0x20))) {
                mstore(add(r, 0x20), mload(add(b, 0x20)))
                mstore(r, add(
                    mload(b),
                    div(mload(a), exp(10, add(mload(add(b, 0x20)), add(not(mload(add(a, 0x20))), 1)))))
                )
            }
        }
    }

    function mul(Float memory a, Float memory b) internal pure returns (Float memory r) {
        bool isNegativeA;
        bool isNegativeB;
        assembly {
            if gt(shr(255, mload(a)), 0) {
                mstore(a, add(not(mload(a)), 1))
                isNegativeA := 1
            }
            if gt(shr(255, mload(b)), 0) {
                mstore(b,  add(not(mload(b)), 1))
                isNegativeB := 1
            }
            mstore(r, mul(mload(a), mload(b)))
            mstore(add(r, 0x20), add(mload(add(a, 0x20)), mload(add(b, 0x20))))
        }

        uint256 rawResultSize = findNumberOfDigits(uint(r.significand));
        assembly {
            if gt(rawResultSize, 38) {
                let expReducer := sub(rawResultSize, 38)
                mstore(r, div(mload(r), exp(10, expReducer)))
                mstore(add(r, 0x20), add(mload(add(r, 0x20)), expReducer))
            }
            if xor(isNegativeA, isNegativeB) {
                mstore(r, add(not(mload(r)), 1))
            }
        }
    }

    function div(Float memory a, Float memory b) internal pure returns (Float memory r) {
        bool negativeA;
        bool negativeB;
        assembly{
            if gt(shr(255,mload(a)),0){
                negativeA := 1
                mstore(a, add(not(mload(a)), 1))
            }
            if gt(shr(255,mload(b)),0){
                negativeB := 1
                mstore(b, add(not(mload(b)), 1))
            }
        }
        uint digitsA = findNumberOfDigits(uint(a.significand));
        assembly{
            let expMultiplier := sub(MAX_DIGITS_X_2, digitsA)
            mstore(a, mul(mload(a), exp(BASE, expMultiplier)))
            let negExpMultiplier := add(not(expMultiplier), 1)
            mstore(add(a, 0x20), add(mload(add(a, 0x20)),  negExpMultiplier))
            mstore(r, div(mload(a), mload(b)))
        }
        console2.log("a.significand", a.significand);
        console2.log("a.exponent", a.exponent);
        uint rawResultSize = findNumberOfDigits(uint(r.significand));
        console2.log("r.significand", r.significand);
        console2.log("rawResultSize", rawResultSize);
        assembly{
            let expReducer := add(rawResultSize, add(not(MAX_DIGITS), 1))
            mstore(add(r, 0x20), add( add(mload(add(a, 0x20)), add(not(mload(add(b, 0x20))), 1)), expReducer))
            if gt(shr(255,expReducer),0){
                mstore(r, div(mload(r), exp(BASE, expReducer)))
            }
            if iszero(gt(shr(255,expReducer),0)){
                expReducer := add(not(expReducer), 1)
                mstore(r, mul(mload(r), exp(BASE, expReducer)))
            }
            if xor(negativeA, negativeB){
                mstore(r, add(not(mload(r)), 1))
            }
        }
    }

}