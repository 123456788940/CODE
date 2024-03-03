// SPDX-License-Identifier: MIT
pragma solidity ^0.8;


import "./ACOMToken.sol"; 

contract taskManagerSystem   {
    AGEMSToken public acomToken;
    address public client;
    address public user;
    address public owner;
    bool reentrancyLock;

    mapping(address => string) public taskName;
    
    mapping(address => string) public notification;

    struct authenticateUser {
        uint userId;
        string userName;
        address userAddress;
    }

    mapping(address=>authenticateUser) public userAuthentication;

    struct taskManager {
        bool projectApplied;
        string formerProjects;
        uint[] skills;
        bool taskAssigned;
        address taskAssignedTo;
        string projectName;
        uint projectId;
        bool fundsEscrowed;
        bool fundsReleased;
        uint amount;
    }

    mapping(address => taskManager) public manageTask;

    struct ReviewSystem {
        bool reviewed;
        bool taskCompleted;
        address reviewer;
    }

    mapping(address => ReviewSystem) public systemOfReview;

    // contructor to initialize some state variables
    constructor(address _client, address _user, address _acomTokenAddress) {
        owner = msg.sender;
        client = _client;
        user = _user;
        acomToken = AGEMSToken(_acomTokenAddress);
    }

    // onlyClient modifier
    modifier onlyClient() {
        require(msg.sender == client, "only client can call this function");
        _;
    }

    modifier nonReentrant() {
        require(!reentrancyLock, "reentrancyGuard"); 
        reentrancyLock = true;
        _;
        reentrancyLock = false;

    }

      // onlyOwner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

      // onlyUser modifier
    modifier onlyUser() {
        require(msg.sender == user, "only user can call this function");
        _;
    }

    // Authenticate user function
    function _authenticateUser(address _user, uint _userId, string memory _userName) external onlyUser onlyClient {
       require(_user != address(0), "Address must be valid");
       require(userAuthentication[_user].userAddress == address(0), "User already authenticated");
       userAuthentication[_user] = authenticateUser(_userId, _userName, _user);
    }

    // post task function
    function postTask(string memory _taskName) external onlyClient {
        taskName[msg.sender] = _taskName;
          emit NotificationSent(client, "New task posted, users can now apply");
        
    }
     // applyForProject function
    function applyForProject(uint[] memory skills, string memory _formerProjects) external onlyUser {
        require(!manageTask[msg.sender].projectApplied, "Already applied for  a project");
        manageTask[msg.sender] = taskManager(true, _formerProjects, skills, false, address(0), "", 0,  false, false, 0);

    }

 

     // Assign project function
    function assignProject(address _user, string memory _projectName, uint _projectId, uint _amount) external onlyClient {
        require(!manageTask[_user].taskAssigned, "Task already assigned");
        manageTask[_user].taskAssigned = true;
        manageTask[_user].taskAssignedTo = _user;
        manageTask[_user].projectName = _projectName;
        manageTask[_user].projectId = _projectId;
        manageTask[_user].amount = _amount;
    }

     // Show skillsets function
    function showSkillsets(address _user) external view returns (uint[] memory) {
        return manageTask[_user].skills;
    }

    // Show former projects function
    function showFormerProjects(address _user) external view returns (string memory) {
        return manageTask[_user].formerProjects;
    }

    // Escrow funds function
    function escrowFunds(uint _amount) external nonReentrant {
        taskManager storage task = manageTask[msg.sender];
        require(task.taskAssigned, "No task assigned");
        require(!task.fundsEscrowed, "Funds already escrowed");

        // Transfer ACOM tokens for escrow
        require(acomToken.transferFrom(msg.sender, address(this), _amount), "ACOM transfer failed");

        task.fundsEscrowed = true;
    }


    // Review task function
    function reviewTask(address _reviewer) external onlyClient onlyUser {
        _reviewer = client;
        systemOfReview[_reviewer].reviewed = true;
    }

    // Complete task function
    function completeTask(address _reviewer) external onlyClient onlyUser {
        _reviewer = client;
        systemOfReview[_reviewer].taskCompleted = true;
    }

    // Pay for task function
    function payForTask(address _user) external nonReentrant {
        taskManager storage task = manageTask[_user];
        require(task.fundsEscrowed && !task.fundsReleased, "Funds not escrowed or already released");
        require(systemOfReview[_user].reviewed && systemOfReview[_user].taskCompleted, "Task not reviewed or completed");

        // Transfer ACOM tokens for payment
        require(acomToken.transfer(task.taskAssignedTo, task.amount), "ACOM transfer failed");

        task.fundsReleased = true;

        emit NotificationSent(task.taskAssignedTo, "Payment received for task");
    }


    // Notify function
    function notify(address _recipient, string memory _updateType) external onlyClient onlyUser {
        string memory notificationMessage;

        if (keccak256(abi.encodePacked(_updateType)) == keccak256(abi.encodePacked("update"))) {
            notificationMessage = "New update available for the project.";
        } else if (keccak256(abi.encodePacked(_updateType)) == keccak256(abi.encodePacked("payment"))) {
            notificationMessage = "Payment has been made for the project.";
        } else if (keccak256(abi.encodePacked(_updateType)) == keccak256(abi.encodePacked("deadline"))) {
            notificationMessage = "Deadline for the project is approaching.";
        } else {
            revert("Invalid update type.");
        }

        notification[_recipient] = notificationMessage;
        emit NotificationSent(_recipient, notificationMessage);
    }

    // Notification event
    event NotificationSent(address indexed recipient, string notification);

}
