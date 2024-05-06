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
        uint256 status;
    }

    // status 1 = active
    // status 2 = under review for withdrawal
    // status 3 = authorized for withdrawal

    address owner;
    uint256 purchasedPlans;

    mapping(address user => PlanByUser activePlan) activePlanByUser;
    mapping(address user => PlanByUser activePlan) activeRequestByUser;

    event LogBuyPlan(address indexed user, uint256 indexed planId);
    event LogDeletePlan(address indexed user, uint256 indexed planId);
    event LogRequestWithdraw(address indexed user, uint256 indexed planId);
    event LogAuthorizeWithdraw(
        address indexed user, uint256 indexed planId, address ownerWhoAuthorized
    );
    event LogWithdraw(address indexed user, uint256 indexed planId);

    error InvalidPlandId();
    error InvalidAddress();
    error InvalidValue();
    error PlanHasActiveRequest();
    error UserShouldBeAdmin();

    constructor() {
        owner = msg.sender;
    }

    function test() public pure returns (string memory) {
        return "Hello World!";
    }

    function buyPlan(uint256 id) public {
        if (id < 0) {
            revert InvalidPlandId();
        }

        if (address(msg.sender) == address(0)) {
            revert InvalidAddress();
        }

        PlanByUser memory newPlan = PlanByUser({
            plan: Plan({ id: ++purchasedPlans}),
            user: msg.sender,
            finishDate: block.timestamp + 365 days,
            status: 1
        });

        activePlanByUser[msg.sender] = newPlan;

        emit LogBuyPlan(msg.sender, id);
    }

    function cancelPlan() public {
        uint256 planId = activePlanByUser[msg.sender].plan.id;

        verifyAddress(msg.sender);
        verifyIfUserHasActiveRequest(activePlanByUser[msg.sender]);

        delete activePlanByUser[msg.sender];

        emit LogDeletePlan(msg.sender, planId);
    }

    function requestWithdraw() public {
        uint256 planId = activePlanByUser[msg.sender].plan.id;

        verifyAddress(msg.sender);
        verifyIfUserHasActiveRequest(activePlanByUser[msg.sender]);

        // Immediately release withdrawal for testing
        activePlanByUser[msg.sender].status = 3;
        activeRequestByUser[msg.sender] = activePlanByUser[msg.sender];

        emit LogRequestWithdraw(msg.sender, planId);
    }

    function authorizeWithdraw(address userWhoRequested) public {
        verifyIfUserIsAdmin(msg.sender);

        activePlanByUser[userWhoRequested].status = 3;

        emit LogAuthorizeWithdraw(
            userWhoRequested,
            activePlanByUser[userWhoRequested].plan.id,
            msg.sender
        );
    }

    function withdraw() public { 

        delete activePlanByUser[msg.sender];
        delete activeRequestByUser[msg.sender];

        emit LogWithdraw(msg.sender, activePlanByUser[msg.sender].plan.id);
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
