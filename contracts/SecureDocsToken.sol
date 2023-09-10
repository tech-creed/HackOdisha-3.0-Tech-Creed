// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SecureDocsToken is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter public certificateCounter;

    struct Certificate {
        string ownerName;
        string docName;
        string data; // (just small description about certificate)
        bool validated;
        uint256 tokenId;
        string URI;
    }

    // account data
    mapping(address => bool) public GovernmentAccounts;
    mapping(address => bool) public InduvitualsAccounts;

    // certificates details data
    mapping(address => Certificate) public certificates;

    // log important contract actions
    event CertificateUploaded(
        address indexed owner,
        uint256 indexed certificateId
    );
    event CertificateValidated(uint256 indexed certificateId, bool validated);

    // ====== ERC-721 NFT token name, symbol and baseURI defined =====
    constructor() ERC721("SecureDocsToken", "SDT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "http://localhost:8000/";
    }

    // ====== grant the privilege for the given address =====
    function grantGovernmentPrivilege(address _account) public {
        require(address(0) != _account, "need to send a valid address");
        GovernmentAccounts[_account] = true;
    }

    function grantInduvitualsPrivilege(address _account) public {
        require(address(0) != _account, "need to send a valid address");
        InduvitualsAccounts[_account] = true;
    }

    // ===== based on their role specific task they can do =====
    modifier onlyGovernment() {
        require(
            GovernmentAccounts[msg.sender] == true,
            "only government authority can use this function"
        );
        _;
    }

    modifier onlyInduvituals() {
        require(
            InduvitualsAccounts[msg.sender] == true,
            "only Induvituals can use this function"
        );
        _;
    }

    // check string is valid
    function isStringValid(string memory _str) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        return strBytes.length > 0;
    }

    // Mint token (Induvituals functionalities)
    function mintDocument(
        address _to,
        string memory _ownerName,
        string memory _docName,
        string memory _data,
        string memory _URI
    ) public onlyInduvituals {
        require(
            InduvitualsAccounts[_to] == true,
            "to address must be a Induvituals"
        );
        require(isStringValid(_ownerName), "Input _ownerName string is empty");
        require(isStringValid(_docName), "Input _docName string is empty");
        require(isStringValid(_data), "Input _data string is empty");
        require(isStringValid(_URI), "Input _URI string is empty");

        uint256 tokenId = certificateCounter.current();
        // mint NFT token
        _safeMint(_to, tokenId);
        // Set the metadata URI for the NFT
        _setTokenURI(tokenId, _URI);

        certificates[_to] = Certificate(
            _ownerName,
            _docName,
            _data,
            false,
            tokenId,
            _URI
        );
        certificateCounter.increment();
        emit CertificateUploaded(_to, tokenId);
    }

    // property listings for marketplace (Induvituals functionalities)

    // property listing data
    uint256 propertyListingCount;
    struct PropertyListing {
        address owner;
        string ownerName;
        uint256 price;
        string docName;
        string data;
        bool validated;
        string description;
        bool isActive;
        uint256 tokenId;
    }

    mapping(uint256 => PropertyListing) public propertyListings;

    // event logs about marketplace functionalities
    event PropertyTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );
    event PropertyListed(address indexed ownerAddress, uint256 price);
    event PropertyPurchasedFromMarketplace(
        address oldOwner,
        address indexed newOwner,
        uint256 _price,
        uint256 tokenId
    );

    // token checking
    modifier tokenCheck(uint256 _tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not the token owner");
        _;
    }

    // property listing for the marketplace
    function createPropertyListing(
        uint256 _tokenId,
        uint256 _price,
        string memory _description
    ) public onlyInduvituals tokenCheck(_tokenId) {
        require(_price > 0, "Invalid price amount");
        require(
            isStringValid(_description),
            "Input _description string is empty"
        );

        Certificate storage certificateDetails = certificates[msg.sender];

        propertyListings[propertyListingCount] = PropertyListing(
            msg.sender,
            certificateDetails.ownerName,
            _price,
            certificateDetails.docName,
            certificateDetails.data,
            certificateDetails.validated,
            _description,
            true,
            _tokenId
        );
        propertyListingCount += 1;
        emit PropertyListed(msg.sender, _price);
    }

    // set approval for the buyer
    function setApprovalForToken(
        address _to,
        uint256 _tokenId
    ) public onlyInduvituals tokenCheck(_tokenId) {
        approve(_to, _tokenId);
    }

    // transfer the ownership to the buyer
    function purchaseProperty(
        uint256 _listedId,
        string memory _newOwnerName,
        string memory _newURI
    ) public payable onlyInduvituals {
        PropertyListing storage listing = propertyListings[_listedId];

        require(_exists(listing.tokenId), "Token does not exist");
        require(listing.isActive, "Listing is not active");
        require(
            msg.value >= listing.price,
            "Insufficient funds to purchase the property"
        );

        address oldOwner = ownerOf(listing.tokenId);
        require(oldOwner != msg.sender, "You already own this property");
        require(
            isStringValid(_newOwnerName),
            "Input _newOwnerName string is empty"
        );
        require(isStringValid(_newURI), "Input _newURI string is empty");
        require(
            _isApprovedOrOwner(msg.sender, listing.tokenId),
            "Caller is not token owner or approved"
        );

        // transfer ownership of the NFT to the new owner
        safeTransferFrom(oldOwner, msg.sender, listing.tokenId);
        _setTokenURI(listing.tokenId, _newURI);

        payable(oldOwner).transfer(msg.value);

        listing.isActive = false;

        certificates[msg.sender] = Certificate(
            _newOwnerName,
            listing.docName,
            listing.data,
            false,
            listing.tokenId,
            _newURI
        );

        emit PropertyPurchasedFromMarketplace(
            oldOwner,
            msg.sender,
            msg.value,
            listing.tokenId
        );
    }

    // digital locker functionalities for each induvituals user (Induvituals functionalities)

    // digital locker data
    mapping(address => mapping(uint256 => bool)) private digitalLocker;

    // log the digital locker updates
    event DigitalLockerUpdated(
        address indexed owner,
        uint256 tokenId,
        bool added
    );

    // add the induvituals user on the digital locker
    function addToDigitalLocker(
        uint256 _tokenId
    ) external onlyInduvituals tokenCheck(_tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You don't own this token");
        require(
            !digitalLocker[msg.sender][_tokenId],
            "Token is already in the digital locker"
        );

        digitalLocker[msg.sender][_tokenId] = true;
        emit DigitalLockerUpdated(msg.sender, _tokenId, true);
    }

    // remove the induvituals user on the digital locker
    function removeFromDigitalLocker(
        uint256 _tokenId
    ) external onlyInduvituals tokenCheck(_tokenId) {
        require(ownerOf(_tokenId) == msg.sender, "You don't own this token");
        require(
            digitalLocker[msg.sender][_tokenId],
            "Token is not in the digital locker"
        );

        digitalLocker[msg.sender][_tokenId] = false;
        emit DigitalLockerUpdated(msg.sender, _tokenId, false);
    }

    // check the induvituals user is in the digital locker
    function isInDigitalLocker(
        address _owner,
        uint256 _tokenId
    ) public view returns (bool) {
        require(_owner > address(0), "Invalid _owner address");
        return digitalLocker[_owner][_tokenId];
    }

    // property verification functionalities for each induvitual user's documets (Induvituals functionalities)

    // property verification data
    struct VerificationRequest {
        address requester;
        address governmentAddress;
        uint256 tokenId;
        bool isVerified;
    }

    mapping(uint256 => VerificationRequest) public verificationRequests;
    uint256 public verificationRequestId;

    // log events of the property verification process
    event DocumentVerificationRequested(
        uint256 indexed requestId,
        address indexed requester,
        address indexed governmentAddress,
        uint256 tokenId
    );
    event DocumentVerificationResult(
        uint256 indexed requestId,
        address indexed requester,
        bool _isValid
    );

    // request document verification from induvitual user's to government
    function requestDocumentVerification(
        uint256 _tokenId,
        address _govAddress
    ) external onlyInduvituals tokenCheck(_tokenId) {
        require(
            GovernmentAccounts[_govAddress] == true,
            "Invalid government address"
        );

        verificationRequests[verificationRequestId++] = VerificationRequest(
            msg.sender,
            _govAddress,
            _tokenId,
            false
        );

        emit DocumentVerificationRequested(
            verificationRequestId,
            msg.sender,
            _govAddress,
            _tokenId
        );
    }

    // property verification functionalities for each induvitual user's documets (Government functionalities)

    // validate the induvitual user's documents
    function validateDocumentVerification(
        uint256 _requestId,
        bool _isValid
    ) external onlyGovernment {
        VerificationRequest storage request = verificationRequests[_requestId];
        require(request.requester != address(0), "Invalid request ID");
        require(!request.isVerified, "Request already verified");

        if (_isValid) {
            request.isVerified = true;
        }

        emit DocumentVerificationResult(
            _requestId,
            request.requester,
            _isValid
        );
    }

    // The following functions are overrides required by Solidity.
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) onlyInduvituals {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
