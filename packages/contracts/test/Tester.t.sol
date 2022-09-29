// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract Tester {
    uint256 public inputNumber;
    uint256 public inputNumber2;
    address public inputAddress;
    mapping(address => uint256) public inputMapping;

    constructor() {}

    function setInputVars(
        address user,
        uint256 amount,
        uint256 amount2
    ) external {
        inputAddress = user;
        inputNumber = amount;
        inputNumber2 = amount2;
        inputMapping[user] = amount;
    }

    function doSmth() external {}
}

contract ExampleNFTTest is Test {
    struct Vars {
        address user;
        uint256 amount;
    }

    uint256 internal param1 = 10;
    uint256 internal param2 = 5;
    address internal param3 = address(0x4444);
    uint256 internal addedParam = 100;
    Tester internal tester = new Tester();
    Vars internal vars = Vars({user: param3, amount: param1});
    bytes internal varsEncoded = abi.encode(param3, param1);
    bytes[] internal varsArray = [
        abi.encode(param1),
        abi.encode(param1),
        abi.encode(param1),
        abi.encode(param1)
    ];
    bytes[] internal params1 = [varsEncoded, abi.encode(0)];
    bytes[] internal params2 = [
        abi.encode(param3),
        abi.encode(0),
        abi.encode(param1)
    ];

    function setUp() public {}

    function testMint() internal {
        bytes memory v1a = abi.encodePacked(param1, param2, param3);
        bytes memory v1b = abi.encodePacked(addedParam);
        bytes memory v1 = abi.encodePacked(v1a, v1b);

        bytes memory v2 = abi.encodePacked(param1, param2, param3, addedParam);

        emit log_bytes(v1);
        emit log_bytes(v2);
    }

    function testSetInputVars() internal {
        bytes memory v1 = abi.encodePacked(param3, param1);
        bytes memory v2 = abi.encode(param3, param1);
        bytes memory v3 = abi.encode(param3, param1, 0);
        bytes memory param3Encoded = abi.encode(param3);
        bytes memory param1Encoded = abi.encode(param1);

        emit log_bytes(v1);
        emit log_bytes(v2);
        emit log_bytes(param3Encoded);
        emit log_bytes(param1Encoded);
        emit log_bytes(
            bytes.concat(param3Encoded, param1Encoded, param1Encoded)
        );
        emit log_bytes(bytes.concat(v2, param1Encoded));
        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodePacked(
                bytes4(keccak256("setInputVars(address,uint256,uint256)")),
                bytes.concat(v2, abi.encode(addedParam))
            )
        );
        emit log(success ? "success" : "fail");
        assertEq(tester.inputNumber(), param1);
        assertEq(tester.inputNumber2(), addedParam);
        assertEq(tester.inputAddress(), param3);
        assertEq(tester.inputMapping(param3), param1);
    }

    function testBytesEncoding() internal {
        emit log_bytes(abi.encode(uint256(10)));
        emit log_bytes(abi.encode(int256(10)));
        emit log_bytes(abi.encode(int128(10)));
    }

    function testStruct() internal {
        Vars memory _vars = vars;
    }

    function testBytes() internal {
        (address user, uint256 amount) = abi.decode(
            varsEncoded,
            (address, uint256)
        );
    }

    // 1. Find out if we need to do calculations on the dynamic input
    // 2. Find out which input index is dynamic
    // 3. Slot dynamic input into array at correct index (overwrite)
    // 4. Concat input array
    // NOTICE: if the dynamic input is the first or last element we can simply have a 2 array with the abi encoded elements + the encoded dynamic input

    function encodeArrayIf(bytes[] memory _array)
        internal
        returns (bytes memory)
    {
        uint256 arrayLength = _array.length;
        if (arrayLength == 1) {
            return _array[0];
        } else if (arrayLength == 2) {
            return bytes.concat(_array[0], _array[1]);
        } else if (arrayLength == 3) {
            return bytes.concat(_array[0], _array[1], _array[2]);
        }
        return bytes.concat(_array[0], _array[1], _array[2], _array[3]);
    }

    function testEncodeArrayLoop() internal {
        bytes memory result = encodeArrayLoop(varsArray);
    }

    function testEncodeArrayIf() internal {
        bytes memory result = encodeArrayLoop(varsArray);
    }

    function testDynamicElementLast() internal {
        bytes memory dynamic = abi.encode(addedParam);
        bytes[] memory dynamicParams = params1;
        dynamicParams[1] = dynamic;
        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodePacked(
                bytes4(keccak256("setInputVars(address,uint256,uint256)")),
                encodeArrayLoop(dynamicParams)
            )
        );
        emit log(success ? "success" : "fail");
    }

    function testDynamicElementCenter() internal {
        bytes memory dynamic = abi.encode(addedParam);
        bytes[] memory dynamicParams = params2;
        dynamicParams[1] = dynamic;
        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodePacked(
                bytes4(keccak256("setInputVars(address,uint256,uint256)")),
                encodeArrayLoop(dynamicParams)
            )
        );
        emit log(success ? "success" : "fail");
    }

    function testCallFunctionNormal() internal {
        tester.setInputVars(param3, param1, param1);
    }

    function testCallFunctionEncoded() internal {
        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodePacked(
                bytes4(keccak256("setInputVars(address,uint256,uint256)")),
                abi.encode(param3, param1, param1)
            )
        );
    }

    function testCallDoSmth() public {
        (bool success, bytes memory returnData) = address(tester).call(
            abi.encodePacked(bytes4(keccak256("doSmth()")), "")
        );
        emit log(success ? "success" : "failed");
    }

    // struct InputParams {
    //     bool hasDynamicInput;
    //     bool transformInput;
    //     uint8 dynamicInputIndex;
    //     bytes[] additionalParams;
    //     uint8 additionalParamsLength;
    //     bytes4 signature;
    // }

    // function deposit(uint256 amount) internal {
    //     if (!hasDynamicInput && additionalParamsLength == 0) {
    //         // target.call(sig,"")
    //     }
    //     if (hasDynamicInput) {
    //         if (transformInput) amount = transformAmount(amount);
    //         bytes memory encodedAmount = abi.encode(amount);
    //         if (additionalParamsLength == 0) {
    //             // target.call(sig, encodedAmount);
    //         } else if {
    //           bytes memory data = createData(amount,dynamicInputIndex, additionalParams);
    //           // target.call(sig,data)
    //         }
    //     }
    // }
}
