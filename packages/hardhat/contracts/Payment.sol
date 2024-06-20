//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./AccessControl.sol";

contract Payment {
	uint public nextPlanId;

	struct Plan {
		address merchant;
		address token;
		uint amount;
		uint frequency;
		string name;
	}

	struct Subscription {
		address subscriber;
		uint start;
		uint nextPayment;
	}

	mapping(uint => Plan) public plans;
	mapping(address => mapping(uint => Subscription)) public subscriptions;

	AccessControl public accessControl;

    event PlanCreated(address merchant, uint planId, uint date, string name);

	event SubscriptionCreated(address subscriber, uint planId, uint date);

	event SubscriptionCancelled(address subscriber, uint planId, uint date);

	event PaymentSent(
		address from,
		address to,
		uint amount,
		uint planId,
		uint date
	);

	constructor(address _accessControl) {
		accessControl = AccessControl(_accessControl);
	}

	function createPlan(address token, uint amount, uint frequency, string memory name) external {
		require(token != address(0), "address cannot be null address");
		require(amount > 0, "amount needs to be > 0");
		require(frequency > 0, "frequency needs to be > 0");
		plans[nextPlanId] = Plan(msg.sender, token, amount, frequency, name);
        emit PlanCreated(msg.sender, nextPlanId, block.timestamp, name); 
        nextPlanId++;
	}

	function subscribe(uint planId) external {
		IERC20 token = IERC20(plans[planId].token);
		Plan storage plan = plans[planId];
		require(plan.merchant != address(0), "this plan does not exist");

		token.transferFrom(msg.sender, plan.merchant, plan.amount);
		emit PaymentSent(
			msg.sender,
			plan.merchant,
			plan.amount,
			planId,
			block.timestamp
		);

		subscriptions[msg.sender][planId] = Subscription(
			msg.sender,
			block.timestamp,
			block.timestamp + plan.frequency
		);
		emit SubscriptionCreated(msg.sender, planId, block.timestamp);
	}

	function cancel(uint planId) external {
		Subscription storage subscription = subscriptions[msg.sender][planId];
		require(
			subscription.subscriber != address(0),
			"this subscription does not exist"
		);
		delete subscriptions[msg.sender][planId];
		emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
	}

	function payByContract(address subscriber, uint planId) external {
		require(
			accessControl.isPaymentContract(msg.sender),
			"Caller is not an authorized payment contract"
		);

		Subscription storage subscription = subscriptions[subscriber][planId];
		Plan storage plan = plans[planId];
		IERC20 token = IERC20(plan.token);
		require(
			subscription.subscriber != address(0),
			"This subscription does not exist"
		);
		require(
			block.timestamp > subscription.nextPayment,
			"Payment not due yet"
		);

		token.transferFrom(subscriber, plan.merchant, plan.amount);
		emit PaymentSent(
			subscriber,
			plan.merchant,
			plan.amount,
			planId,
			block.timestamp
		);
		subscription.nextPayment += plan.frequency;
	}
}
