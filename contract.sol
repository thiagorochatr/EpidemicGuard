// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2Plus.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2_5.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import "./Base64.sol";

// contract OutbreakResponseSystem is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
contract OutbreakResponseSystem is VRFConsumerBaseV2Plus, ERC721URIStorage {
    using Counters for Counters.Counter;

    struct Resource {
        string resourceType;
        string location;
        bool isAvailable;
    }

    struct Prediction {
        string location;
        string disease;
        uint256 riskLevel;
        uint256 predictionDate;
    }

    Counters.Counter private _tokenIds;
    mapping(uint256 => Resource) public resources;
    mapping(uint256 => Prediction) public predictions;
    uint256 public latestPredictionId;

    // VRFCoordinatorV2_5 COORDINATOR;
    AggregatorV3Interface internal dataFeed;

    uint256 s_subscriptionId;
    bytes32 keyHash = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;

    event ResourceCreated(uint256 tokenId, string resourceType, string location);
    event PredictionMade(uint256 predictionId, string location, string disease, uint256 riskLevel);
    event OutbreakAlert(string location, string disease, uint256 riskLevel);
    event Teste(uint256 id);

    constructor(uint256 subscriptionId) 
    ERC721("OutbreakResponse", "OBR") 
    // VRFConsumerBaseV2(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
    VRFConsumerBaseV2Plus(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625)
{
    // COORDINATOR = VRFCoordinatorV2_5(0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625); // VRF Coordinator
    s_subscriptionId = subscriptionId;
    dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306); // Data feed ETH/USD
}

    function createResource(string memory resourceType, string memory location) public {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        
        string memory svg = generateSVG(resourceType, location, true);
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked('{"name": "Resource #', toString(newTokenId), '", "description": "A resource for outbreak response", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'))));
        string memory tokenURI = string(abi.encodePacked("data:application/json;base64,", json));
        
        _setTokenURI(newTokenId, tokenURI);
        resources[newTokenId] = Resource(resourceType, location, true);
        emit ResourceCreated(newTokenId, resourceType, location);
    }

    function generateSVG(string memory resourceType, string memory location, bool isAvailable) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="200" viewBox="0 0 300 200">',
            '<style>.title{fill:#2c3e50;font-size:24px;font-weight:bold}.info{fill:#34495e;font-size:16px}.available{fill:#27ae60}.unavailable{fill:#c0392b}</style>',
            '<rect width="100%" height="100%" fill="#ecf0f1"/>',
            '<text x="10" y="30" class="title">Resource NFT</text>',
            '<text x="10" y="60" class="info">Type: ', resourceType, '</text>',
            '<text x="10" y="90" class="info">Location: ', location, '</text>',
            '<text x="10" y="120" class="info">Status: <tspan class="',
            isAvailable ? 'available' : 'unavailable',
            '">', isAvailable ? 'Available' : 'Unavailable', '</tspan></text>',
            '</svg>'
        ));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // function requestRandomWords() external returns (uint256 requestId) {
    //     requestId = COORDINATOR.requestRandomWords(
    //         keyHash,
    //         s_subscriptionId,
    //         requestConfirmations,
    //         callbackGasLimit,
    //         numWords
    //     );
    //     s_requestId = requestId;
    //     return requestId;
    // }

    function requestRandomWords() external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: false
                    })
                )
            })
        );
        s_requestId = requestId;
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) internal override {
        // require(_requestId.exists, "request not found");
        s_randomWords = _randomWords;
        s_requestId = _requestId;

        // Use the random number to select data for AI model or distribute resources
        // uint256 randomIndex = randomWords[0] % _tokenIds.current();
        // Resource memory selectedResource = resources[randomIndex];
        // Logic to use the randomly selected resource
    }

    function getLatestData() public view returns (int) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer; //return answer / 10000000;
    }

    function makePrediction(string memory location, string memory disease, uint256 riskLevel) public {
        latestPredictionId++;
        predictions[latestPredictionId] = Prediction(location, disease, riskLevel, block.timestamp);
        emit PredictionMade(latestPredictionId, location, disease, riskLevel);

        if (riskLevel > 70) { // Assuming risk level is out of 100
            emit OutbreakAlert(location, disease, riskLevel);
        }
    }

    function allocateResource(uint256 tokenId, string memory newLocation) public {
    // require(ERC721(tokenId).tokenOfOwnerByIndex(msg.sender, 0) == tokenId, "Resource does not exist");
    require(ownerOf(tokenId) == msg.sender, "Not the owner of the resource");
    
    Resource storage resource = resources[tokenId];
    resource.location = newLocation;
    resource.isAvailable = false;
    // Logic to handle resource allocation
}

    function getResource(uint256 tokenId) public view returns (string memory, string memory, bool) {
        // require(this._exists(tokenId), "Resource does not exist");
        Resource memory resource = resources[tokenId];
        return (resource.resourceType, resource.location, resource.isAvailable);
    }

    function getPrediction(uint256 predictionId) public view returns (string memory, string memory, uint256, uint256) {
        Prediction memory prediction = predictions[predictionId];
        return (prediction.location, prediction.disease, prediction.riskLevel, prediction.predictionDate);
    }
}
