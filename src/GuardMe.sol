// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GuardMe {
    struct Plan {
        uint256 id;
    }
    
    struct PlanByUser {
        Plan plan;
        address user;
        uint256 finishDate;
        uint256 amountTheUserPaid;
        uint256 status;
    }

    // status 1 = active
    // status 2 = under review for withdrawal
    // status 3 = authorized for withdrawal

    address owner;
    uint256 purchasedPlans;

    mapping(address user => PlanByUser activePlan) activePlanByUser;
    mapping(address user => PlanByUser activePlan) activeRequestByUser;

    event LogBuyPlan(address indexed user, uint256 indexed planId, uint256 amount);
    event LogDeletePlan(address indexed user, uint256 indexed planId, uint256 amount);
    event LogRequestWithdraw(address indexed user, uint256 indexed planId, uint256 amount);
    event LogAuthorizeWithdraw(
        address indexed user, uint256 indexed planId, uint256 amount, address ownerWhoAuthorized
    );
    event LogWithdraw(address indexed user, uint256 indexed planId, uint256 amount);

    error InvalidPlandId();
    error InvalidAddress();
    error InvalidValue();
    error PlanHasActiveRequest();
    error UserShouldBeAdmin();

    constructor() {
        owner = msg.sender;
    }

    function buyPlan(uint256 id) public payable {
        if (id < 0) {
            revert InvalidPlandId();
        }

        if (address(msg.sender) == address(0)) {
            revert InvalidAddress();
        }

        if (msg.value <= 0) {
            revert InvalidValue();
        }

        PlanByUser memory newPlan = PlanByUser({
            plan: Plan({ id: ++purchasedPlans}),
            user: msg.sender,
            finishDate: block.timestamp + 365 days,
            amountTheUserPaid: msg.value,
            status: 1
        });

        activePlanByUser[msg.sender] = newPlan;

        emit LogBuyPlan(msg.sender, id, msg.value);
    }

    function cancelPlan() public {
        uint256 planId = activePlanByUser[msg.sender].plan.id;

        verifyAddress(msg.sender);
        verifyIfUserHasActiveRequest(activePlanByUser[msg.sender]);

        uint256 amountTheUserPaid = activePlanByUser[msg.sender].amountTheUserPaid;

        delete activePlanByUser[msg.sender];

        emit LogDeletePlan(msg.sender, planId, amountTheUserPaid);
    }

    function requestWithdraw() public {
        uint256 planId = activePlanByUser[msg.sender].plan.id;

        verifyAddress(msg.sender);
        verifyIfUserHasActiveRequest(activePlanByUser[msg.sender]);

        activePlanByUser[msg.sender].status = 2;
        activeRequestByUser[msg.sender] = activePlanByUser[msg.sender];

        emit LogRequestWithdraw(msg.sender, planId, activePlanByUser[msg.sender].amountTheUserPaid);
    }

    function authorizeWithdraw(address userWhoRequested) public {
        verifyIfUserIsAdmin(msg.sender);

        activePlanByUser[userWhoRequested].status = 3;

        emit LogAuthorizeWithdraw(
            userWhoRequested,
            activePlanByUser[userWhoRequested].plan.id,
            activePlanByUser[userWhoRequested].amountTheUserPaid,
            msg.sender
        );
    }

    function withdraw() public payable { 
        address payable userWhoReceive = payable(msg.sender);

        uint256 amountToWithdraw = activePlanByUser[msg.sender].amountTheUserPaid;

        delete activePlanByUser[msg.sender];
        delete activeRequestByUser[msg.sender];

        userWhoReceive.transfer(amountToWithdraw);

        emit LogWithdraw(msg.sender, activePlanByUser[msg.sender].plan.id, amountToWithdraw);
    }

    function verifyAddress(address user) private pure {
        if (address(user) == address(0)) {
            revert InvalidAddress();
        }
    }

    function verifyIfUserHasActiveRequest(PlanByUser memory userPlan) private pure {
        if (userPlan.status == 2) {
            revert PlanHasActiveRequest();
        }
    }

    function verifyIfUserIsAdmin(address user) private view {
        if (user != owner) {
            revert UserShouldBeAdmin();
        }
    }
}
