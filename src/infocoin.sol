// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DataPackageManager is ReentrancyGuard {
    struct DataPackage {
        uint256 id;
        string provider;
        uint256 price;
        uint256 dataAmount;
        bool isActive;
    }

    struct Subscription {
        string mobileNumber;
        uint256 packageId;
        uint256 expirationDate;
        bool isActive;
        string provider;
    }

    mapping(uint256 => DataPackage) public dataPackages;
    mapping(address => Subscription) public subscriptions;

    uint256 public packageCount;
    address public owner;
    IERC20 public acceptedToken;

    event DataPackageAdded(
        uint256 indexed id,
        string indexed provider,
        uint256 price,
        uint256 dataAmount
    );
    event SubscriptionCreated(
        address indexed user,
        string indexed mobileNumber,
        string indexed provider,
        uint256 packageId,
        uint256 expirationDate
    );
    event SubscriptionRenewed(
        address indexed user,
        uint256 indexed packageId,
        uint256 newExpirationDate
    );
    event SubscriptionCanceled(address indexed user, uint256 packageId);
    event DataCredited(
        address indexed user,
        string indexed mobileNumber,
        uint256 indexed dataAmount
    );
    event TokensWithdrawn(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(address _acceptedToken) {
        require(_acceptedToken != address(0), "Invalid token address");
        acceptedToken = IERC20(_acceptedToken);
        owner = msg.sender;
    }

    function addDataPackage(
        string memory _provider,
        uint256 _price,
        uint256 _dataAmount
    ) public onlyOwner {
        packageCount++;
        dataPackages[packageCount] = DataPackage(
            packageCount,
            _provider,
            _price,
            _dataAmount,
            true
        );
        emit DataPackageAdded(packageCount, _provider, _price, _dataAmount);
    }

    function subscribe(
        string memory _mobileNumber,
        uint256 _packageId,
        uint256 _amount
    ) public nonReentrant {
        require(msg.sender != address(0), "Invalid caller address");
        require(
            dataPackages[_packageId].isActive,
            "Data package is not active"
        );
        require(
            _amount >= dataPackages[_packageId].price,
            "Insufficient payment"
        );

        // Validate mobile number length
        require(
            bytes(_mobileNumber).length >= 10 &&
                bytes(_mobileNumber).length <= 15,
            "Invalid mobile number length"
        );

        require(
            acceptedToken.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        string memory provider = dataPackages[_packageId].provider;
        subscriptions[msg.sender] = Subscription(
            _mobileNumber,
            _packageId,
            block.timestamp + 30 days,
            true,
            provider
        );

        emit SubscriptionCreated(
            msg.sender,
            _mobileNumber,
            provider,
            _packageId,
            block.timestamp + 30 days
        );
        emit DataCredited(
            msg.sender,
            _mobileNumber,
            dataPackages[_packageId].dataAmount
        );
    }

    function renewSubscription(uint256 _amount) public nonReentrant {
        require(msg.sender != address(0), "Invalid caller address");
        require(subscriptions[msg.sender].isActive, "No active subscription");
        require(!isSubscriptionExpired(msg.sender), "Subscription is expired");
        require(
            _amount >= dataPackages[subscriptions[msg.sender].packageId].price,
            "Insufficient payment"
        );

        require(
            acceptedToken.transferFrom(msg.sender, address(this), _amount),
            "Token transfer failed"
        );

        subscriptions[msg.sender].expirationDate += 30 days;

        emit SubscriptionRenewed(
            msg.sender,
            subscriptions[msg.sender].packageId,
            subscriptions[msg.sender].expirationDate
        );
    }

    function cancelSubscription() public {
        require(msg.sender != address(0), "Invalid caller address");
        require(subscriptions[msg.sender].isActive, "No active subscription");

        subscriptions[msg.sender].isActive = false;
        emit SubscriptionCanceled(
            msg.sender,
            subscriptions[msg.sender].packageId
        );
    }

    function isSubscriptionActive(address user) public view returns (bool) {
        Subscription storage subscription = subscriptions[user];
        return
            subscription.isActive &&
            subscription.expirationDate > block.timestamp;
    }

    function isSubscriptionExpired(address user) public view returns (bool) {
        Subscription storage subscription = subscriptions[user];
        return
            subscription.isActive &&
            subscription.expirationDate <= block.timestamp;
    }

    function withdrawTokens() public onlyOwner {
        uint256 balance = acceptedToken.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        acceptedToken.transfer(owner, balance);
        emit TokensWithdrawn(owner, balance);
    }
}
