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
    uint constant MAX_DIGITS_X_2_PLUS_1 = 77;

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
                aMan := sub(0,aMan)
            }
            if and(b, MANTISSA_SIGN_MASK) {
                bMan := sub(0,bMan)
            }
            let addition := add(aMan, bMan)
            
            if and(TOW_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := sub(0,addition) // convert back from 2's complement
            }
            if gt(addition, 99999999999999999999999999999999999999){
                addition := div(addition, BASE)
                r := add(r, 680564733841876926926749214863536422912) // we add 1 to the exponent
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
                aMan := sub(0,aMan)
            }
            /// we invert the sign for b to do a subtraction instead of an addition
            if xor(b, MANTISSA_SIGN_MASK) {
                bMan := sub(0, bMan)
            }
            let addition := add(aMan, bMan)
            if and(TOW_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := sub(0,addition) // convert back from 2's complement
            }
            r := or(r, addition)
        }
    }

    function mul(float128 a, float128 b) internal pure returns (float128 r) {
        uint rMan;
        uint rExp;
        assembly {
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
    
            rMan := mul(aMan, bMan)
            rExp := sub(add(shr(EXPONENT_BIT, aExp), shr(EXPONENT_BIT, bExp)), ZERO_OFFSET)
        }
        uint256 rawResultSize = findNumberOfDigits(rMan);
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
            aExp := shr(EXPONENT_BIT, and(a, EXPONENT_MASK))
        }
        uint digitsA = findNumberOfDigits(aMan);
        assembly{
            let bMan := and(b, MANTISSA_MASK)
            let expMultiplier := sub(MAX_DIGITS_X_2_PLUS_1, digitsA)
            aMan := mul(aMan, exp(BASE, expMultiplier))
            aExp := sub(aExp,  expMultiplier)
            rMan := div(aMan, bMan)
        }
        uint rawResultSize = findNumberOfDigits(rMan);
        assembly{
            let bExp :=  shr(EXPONENT_BIT, and(b, EXPONENT_MASK))
            rExp := sub(add(aExp, ZERO_OFFSET), bExp)
            let expReducer := sub(rawResultSize, MAX_DIGITS)
            rExp := add(rExp, expReducer)
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
                float := or(MANTISSA_SIGN_MASK, sub(0,mantissa))
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
                exponent := sub(0,sub(ZERO_OFFSET, _exp))
            }
            if gt(_exp, ZERO_OFFSET_MINUS_1) {
                exponent := sub(_exp, ZERO_OFFSET)
            }
            // mantissa
            mantissa := and(float, MANTISSA_MASK)
            /// we use complements 2 for mantissa sign
            if and(float, MANTISSA_SIGN_MASK) {
                mantissa := sub(0,mantissa)
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
        // assembly {
            
        //     if gt(mload(add(a, 0x20)), mload(add(b, 0x20))) {
        //         mstore(add(r, 0x20), mload(add(a, 0x20)))
        //         mstore(
        //             b,
                   
        //                 div(
        //                     mload(b),
        //                     exp(
        //                         BASE,
        //                         add(
        //                             mload(add(a, 0x20)),
        //                             sub(0,mload(add(b, 0x20)))
        //                         )
        //                     )
        //                 )
                    
        //         )
        //     }
        //     if gt(mload(add(b, 0x20)), mload(add(a, 0x20))) {
        //         mstore(add(r, 0x20), mload(add(b, 0x20)))
        //         mstore(
        //             a,
                    
        //                 div(
        //                     mload(a),
        //                     exp(
        //                         BASE,
        //                         add(
        //                             mload(add(b, 0x20)),
        //                             sub(0,mload(add(a, 0x20)))
        //                         )
        //                     )
        //                 )
                    
        //         )
        //     }
        //     if eq(mload(add(a, 0x20)), mload(add(b, 0x20))) {
        //         mstore(add(r, 0x20), mload(add(a, 0x20)))
        //     }

        //     mstore(r, add(mload(a), mload(b)))
        //     if gt(r, 99999999999999999999999999999999999999){
        //         mstore(r, div(r, BASE))
        //         mstore(add(r, 0x20), add(1, mload(r)))
        //     }
        // }
        unchecked{
            if(a.exponent > b.exponent){
                b.significand /= int(BASE**(uint(a.exponent - b.exponent)));
                r.exponent = a.exponent;
            }else if(a.exponent < b.exponent){
                a.significand /= int(BASE**(uint(b.exponent - a.exponent)));
                r.exponent = b.exponent;
            }else r.exponent = a.exponent;

            r.significand = a.significand + b.significand;
            if(r.significand > 99999999999999999999999999999999999999){
                ++r.exponent;
                r.significand /= int(BASE);
            }
        }
    }

    function sub(Float memory a, Float memory b) internal pure returns (Float memory r) {
        // assembly {
        //     /// we negate the sign of b to do subtraction instead of addition
        //     mstore(b, sub(0,mload(add(b, 0x20))))
        //     /// we perform regular addition 
        //     if eq(mload(add(a, 0x20)), mload(add(b, 0x20))) {
        //         mstore(add(r, 0x20), mload(add(a, 0x20)))
        //         mstore(r, add(mload(a), mload(b)))
        //     }
        //     if gt(mload(add(a, 0x20)), mload(add(b, 0x20))) {
        //         mstore(add(r, 0x20), mload(add(a, 0x20)))
        //         mstore(r, add(
        //             mload(a),
        //             div(mload(b), exp(10, add(mload(add(a, 0x20)), sub(0,mload(add(b, 0x20)))))))
        //         )
        //     }
        //     if gt(mload(add(b, 0x20)), mload(add(a, 0x20))) {
        //         mstore(add(r, 0x20), mload(add(b, 0x20)))
        //         mstore(r, add(
        //             mload(b),
        //             div(mload(a), exp(10, add(mload(add(b, 0x20)), sub(0,mload(add(a, 0x20)))))))
        //         )
        //     }
        // }
        unchecked{
            if(a.exponent > b.exponent){
                b.significand /= int(BASE**(uint(a.exponent - b.exponent)));
                r.exponent = a.exponent;
            }else if(a.exponent < b.exponent){
                a.significand /= int(BASE**(uint(b.exponent - a.exponent)));
                r.exponent = b.exponent;
            }else r.exponent = a.exponent;

            r.significand = a.significand - b.significand;
        }
    }

    function mul(Float memory a, Float memory b) internal pure returns (Float memory r) {
        assembly {
            mstore(r, mul(mload(a), mload(b)))
            mstore(add(r, 0x20), add(mload(add(a, 0x20)), mload(add(b, 0x20))))
        }
        uint256 rawResultSize = findNumberOfDigits(uint(r.significand));
        assembly {
            if gt(rawResultSize, MAX_DIGITS) {
                let expReducer := sub(rawResultSize, MAX_DIGITS)
                mstore(r, div(mload(r), exp(BASE, expReducer)))
                mstore(add(r, 0x20), add(mload(add(r, 0x20)), expReducer))
            }
        }
        // unchecked{
        //     r.exponent = a.exponent + b.exponent;
        //     r.significand = a.significand * b.significand;
        //     uint256 rawResultSize = findNumberOfDigits(uint(r.significand));
        //     if(rawResultSize > MAX_DIGITS){
        //         uint expReducer = rawResultSize -  MAX_DIGITS;
        //         r.exponent += int(expReducer);
        //         r.significand /= int(10**expReducer);
        //     }
        // }
    }

    function div(Float memory a, Float memory b) internal pure returns (Float memory r) {
        bool negativeA;
        bool negativeB;
        assembly{
            if gt(shr(255,mload(a)),0){
                negativeA := 1
                mstore(a, sub(0,mload(a)))
            }
            if gt(shr(255,mload(b)),0){
                negativeB := 1
                mstore(b, sub(0,mload(b)))
            }
        }
        uint digitsA = findNumberOfDigits(uint(a.significand));
        assembly{
            let expMultiplier := sub(MAX_DIGITS_X_2_PLUS_1, digitsA)
            mstore(a, mul(mload(a), exp(BASE, expMultiplier)))
            let negExpMultiplier := sub(0,expMultiplier)
            mstore(add(a, 0x20), add(mload(add(a, 0x20)),  negExpMultiplier))
            mstore(r, div(mload(a), mload(b)))
            mstore(add(0x20, r), add(mload(add(0x20, a)), sub(0,mload(add(0x20, b)))))
        }
        uint rawResultSize = findNumberOfDigits(uint(r.significand));
        assembly{
            let expReducer := add(rawResultSize, sub(0,MAX_DIGITS))
            mstore(add(r, 0x20), add(mload(add(r, 0x20)), expReducer))
            if iszero(gt(shr(255,expReducer),0)){
                mstore(r, div(mload(r), exp(BASE, expReducer)))
            }
            if gt(shr(255,expReducer),0){
                expReducer := sub(0,expReducer)
                mstore(r, mul(mload(r), exp(BASE, expReducer)))
            }
            if xor(negativeA, negativeB){
                mstore(r, sub(0,mload(r)))
            }
        }
        // unchecked{
        //     /// this method can only have 37 digits of precision
        //     uint digitsA = findNumberOfDigits(uint(a.significand));
        //     uint expMultiplier = MAX_DIGITS_X_2 - digitsA;
        //     a.significand *= int(10**expMultiplier);
        //     a.exponent -= int(expMultiplier);
        //     r.exponent = a.exponent - b.exponent;
        //     r.significand = a.significand / b.significand;
        //     uint256 rawResultSize = findNumberOfDigits(uint(r.significand));
        //     int expReducer = int(rawResultSize) -  int(MAX_DIGITS);
        //     r.exponent += expReducer;
        //     if (expReducer >= 0) r.significand /= int(10**uint(expReducer));
        //     else r.significand *= int(10**uint(expReducer * -1));
            
        // }
    }

}