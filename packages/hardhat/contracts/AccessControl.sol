
contract AccessControl {
	address public owner;
	mapping(address => bool) public paymentContracts;

	event PaymentContractAdded(address indexed contractAddress);
	event PaymentContractRemoved(address indexed contractAddress);

	modifier onlyOwner() {
		require(msg.sender == owner, "Only owner can call this function");
		_;
	}

	constructor() {
		owner = msg.sender;
	}

	function addPaymentContract(address _contractAddress) external onlyOwner {
		paymentContracts[_contractAddress] = true;
		emit PaymentContractAdded(_contractAddress);
	}

	function removePaymentContract(
		address _contractAddress
	) external onlyOwner {
		paymentContracts[_contractAddress] = false;
		emit PaymentContractRemoved(_contractAddress);
	}

	function isPaymentContract(
		address _contractAddress
	) external view returns (bool) {
		return paymentContracts[_contractAddress];
	}
}