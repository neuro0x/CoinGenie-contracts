// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPaymentTracker {
    enum PayoutCategory {
        Treasury,
        Dev,
        Legal,
        Marketing
    }

    struct Payout {
        address payable receiver;
        uint256 share;
    }

    struct Totals {
        uint256 totalShares;
        uint256 totalReleased;
        uint256 totalOwedToAffiliates;
    }

    struct Affiliate {
        uint256 amountReceived;
        uint256 amountPaid;
        uint256 amountOwed;
        address[] tokensReferred;
        mapping(address tokenAddress => bool) isTokenReferred;
        mapping(address tokenAddress => uint256) amountEarnedByToken;
    }

    event ShareUpdated(address indexed account, uint256 indexed shares);
    event PayeeAdded(address indexed account, uint256 indexed shares);
    event PaymentReleased(address indexed to, uint256 indexed amount);
    event PaymentReceived(address indexed from, uint256 indexed amount);

    error NoPayees();
    error PaymentFailed();
    error SharesAreZero();
    error GenieAlreadySet();
    error AccountIsZeroAddress();
    error NoAmountOwedToAffiliate();
    error AccountAlreadyHasShares();
    error InvalidShares(uint256 shares);
    error AccountNotDuePayment(address account);
    error ZeroSharesForAccount(address account);
    error InvalidAffiliatePercent(uint256 affiliatePercent, uint256 maxBps);
    error PayeeShareLengthMisMatch(uint256 payeesLength, uint256 sharesLength);

    function totalShares() external view returns (uint256);
    function totalReleased() external view returns (uint256);
    function shares(address account) external view returns (uint256);
    function released(address account) external view returns (uint256);
    function payee(uint256 index) external view returns (address);
    function payeeCount() external view returns (uint256);
    function amountOwedToAllAffiliates() external view returns (uint256);
    function amountOwedToAffiliate(address account) external view returns (uint256);
    function amountPaidToAffiliate(address account) external view returns (uint256);
    function getAffiliates() external view returns (address[] memory);
    function getNumberOfAffiliates() external view returns (uint256);
    function getTokensReferredByAffiliate(address account) external view returns (address[] memory);
    function amountEarnedByAffiliateByToken(address account, address tokenAddress) external view returns (uint256);
    function affiliateFeePercent() external view returns (uint256);
    function affiliateRelease(address payable account, address genie_) external;
    function setAffiliatePercent(uint256 newAffiliatePercent) external;
    function release(address payable account) external;
    function updateSplit(address[] calldata payees_, uint256[] calldata shares_) external;
}
