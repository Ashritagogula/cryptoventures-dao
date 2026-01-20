// SPDX-License-Identifier: MIT
/// @notice Creates a new governance proposal

pragma solidity ^0.8.20;

contract DAOGovernance {

    /* ========== ENUMS ========== */

    enum ProposalType {
        HighConviction,
        Experimental,
        Operational
    }


    enum ProposalState {
        Pending,
        Active,
        Defeated,
        Queued,
        Executed,
        Canceled
    }


    /* ========== STRUCTS ========== */

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        address recipient;
        uint256 amount;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        ProposalState state;
        uint256 eta;
        mapping(address => bool) hasVoted;
    }

    struct Receipt {
        bool hasVoted;
        uint8 support;
        uint256 votes;
    }

    struct MemberStake {
        uint256 amount;
        address delegate;
        uint256 delegatedPower;
    }

    struct TreasuryCategory {
        uint256 allocation;
        uint256 spent;
    }

    /* ========== STORAGE ========== */

    address public admin;
    address public guardian;
    bool public paused;

    uint256 public proposalCount;
    uint256 public totalStaked;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => Receipt)) public receipts;
    mapping(address => MemberStake) public members;
    mapping(ProposalType => TreasuryCategory) public treasury;

    /* ========== CONSTANTS ========== */

    uint256 public constant MIN_PROPOSAL_STAKE = 1 ether;

    uint256 public constant TIMELOCK_HIGH = 7 days;
    uint256 public constant TIMELOCK_EXPERIMENTAL = 3 days;
    uint256 public constant TIMELOCK_OPERATIONAL = 1 days;

    /* ========== EVENTS ========== */

    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        ProposalType proposalType,
        uint256 amount
    );

    event VoteCast(
        uint256 indexed proposalId,
        address indexed voter,
        uint8 support,
        uint256 weight
    );

    event DelegationChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    event ProposalQueued(uint256 indexed proposalId, uint256 eta);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    event Paused();
    event Unpaused();

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == guardian, "Not guardian");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "System paused");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor() {
        admin = msg.sender;
        guardian = msg.sender;

        treasury[ProposalType.HighConviction].allocation = 60;
        treasury[ProposalType.Experimental].allocation = 30;
        treasury[ProposalType.Operational].allocation = 10;
    }

    /* ========== ADMIN CONTROLS ========== */

    function setGuardian(address newGuardian) external onlyAdmin {
        require(newGuardian != address(0), "Invalid address");
        guardian = newGuardian;
    }

    function pause() external onlyGuardian {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyGuardian {
        paused = false;
        emit Unpaused();
    }

    /* ========== STAKE MANAGEMENT ========== */

    function deposit() external payable whenNotPaused {
        require(msg.value > 0, "Deposit must be greater than zero");
        members[msg.sender].amount += msg.value;
        totalStaked += msg.value;
    }

    function getVotingPower(address member) public view returns (uint256) {
        return _sqrt(members[member].amount + members[member].delegatedPower);
    }

    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /* ========== DELEGATION ========== */

    function delegate(address to) external whenNotPaused {
        require(to != msg.sender, "Cannot delegate to self");

        MemberStake storage sender = members[msg.sender];
        address previousDelegate = sender.delegate;

        if (previousDelegate != address(0)) {
            members[previousDelegate].delegatedPower -= sender.amount;
        }

        sender.delegate = to;
        members[to].delegatedPower += sender.amount;

        emit DelegationChanged(msg.sender, previousDelegate, to);
    }

    /* ========== PROPOSAL CREATION ========== */

    function propose(
        ProposalType pType,
        address recipient,
        uint256 amount,
        string calldata description
    ) external whenNotPaused returns (uint256) {
        require(members[msg.sender].amount >= MIN_PROPOSAL_STAKE, "Insufficient stake");
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");

        proposalCount++;

        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.proposalType = pType;
        p.recipient = recipient;
        p.amount = amount;
        p.description = description;
        p.startBlock = block.number + 1;
        p.endBlock = block.number + 100;
        p.state = ProposalState.Pending;

        emit ProposalCreated(proposalCount, msg.sender, pType, amount);
        return proposalCount;
    }

    /* ========== PROPOSAL STATE VIEW ========== */

    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage p = proposals[proposalId];

        if (p.state == ProposalState.Executed || p.state == ProposalState.Canceled) {
            return p.state;
        }

        if (block.number < p.startBlock) {
            return ProposalState.Pending;
        }

        if (block.number <= p.endBlock) {
            return ProposalState.Active;
        }

        if (p.forVotes <= p.againstVotes) {
            return ProposalState.Defeated;
        }

        return ProposalState.Queued;
    }

    /* ========== VOTING ========== */

    function castVote(uint256 proposalId, uint8 support) external whenNotPaused {
        require(support <= 2, "Invalid vote");
        Proposal storage p = proposals[proposalId];

        require(getProposalState(proposalId) == ProposalState.Active, "Voting not active");
        require(!p.hasVoted[msg.sender], "Already voted");

        uint256 weight = getVotingPower(msg.sender);
        require(weight > 0, "No voting power");

        p.hasVoted[msg.sender] = true;
        receipts[proposalId][msg.sender] = Receipt(true, support, weight);

        if (support == 0) {
            p.againstVotes += weight;
        } else if (support == 1) {
            p.forVotes += weight;
        } else {
            p.abstainVotes += weight;
        }

        emit VoteCast(proposalId, msg.sender, support, weight);
    }

    /* ========== TIMELOCK & EXECUTION ========== */

    function queue(uint256 proposalId) external whenNotPaused {
        Proposal storage p = proposals[proposalId];

        require(getProposalState(proposalId) == ProposalState.Queued, "Not approved");
        require(p.eta == 0, "Already queued");

        uint256 delay = p.proposalType == ProposalType.HighConviction
            ? TIMELOCK_HIGH
            : p.proposalType == ProposalType.Experimental
                ? TIMELOCK_EXPERIMENTAL
                : TIMELOCK_OPERATIONAL;

        p.eta = block.timestamp + delay;
        emit ProposalQueued(proposalId, p.eta);
    }

    function execute(uint256 proposalId) external whenNotPaused {
        Proposal storage p = proposals[proposalId];

        require(p.eta != 0, "Not queued");
        require(block.timestamp >= p.eta, "Timelock not expired");
        require(p.state != ProposalState.Executed, "Already executed");

        TreasuryCategory storage cat = treasury[p.proposalType];
        uint256 maxAllowed = (address(this).balance * cat.allocation) / 100;
        require(cat.spent + p.amount <= maxAllowed, "Category limit exceeded");
        require(address(this).balance >= p.amount, "Insufficient funds");

        cat.spent += p.amount;
        p.state = ProposalState.Executed;

        (bool ok, ) = p.recipient.call{value: p.amount}("");
        require(ok, "Transfer failed");

        emit ProposalExecuted(proposalId);
    }

    /* ========== EMERGENCY ========== */

    function cancel(uint256 proposalId) external onlyGuardian {
        Proposal storage p = proposals[proposalId];
        require(p.state != ProposalState.Executed, "Already executed");

        p.state = ProposalState.Canceled;
        emit ProposalCanceled(proposalId);
    }
}
