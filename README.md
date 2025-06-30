# Last-Bid-Auction

## Overview

**Last-Bid-Auction** is a smart contract project that implements a "Last Bid Auction" mechanism. In this type of auction, the winner is determined based on the last valid bid placed before the auction expires. The repository is written in Solidity and includes a complete Typescript test suite. The project is ready for production deployment.

## Features

- **Smart Contract Logic**: Implements a last-bid-wins auction mechanism.
- **Comprehensive Tests**: Includes a full test suite for all contract functions.
- **Ready to Deploy**: Codebase is production-ready.
- **MIT Licensed**: Open-source under the MIT License.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Smart Contract Details](#smart-contract-details)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)
- [License](#license)

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/txich/Last-Bid-Auction.git
   cd Last-Bid-Auction
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

## Usage

After installing dependencies, you can interact with, test, and deploy the smart contract. The project is designed for developer and auditor ease-of-use.

## Smart Contract Details

The smart contract implements a last-bid auction with the following characteristics:

- **Bid Submission**: Participants can submit bids until the auction end time.
- **Winner Selection**: The last valid bid before the auction closes determines the winner.
- **Security**: Follows best practices for smart contract security and bid validation.

> _See the contract code and comments for full implementation details._

## Testing

The repository includes a comprehensive suite of tests covering all core contract functions and edge cases.

To run the tests:

```bash
npx hardhat test
```

Test coverage includes:

- Bid placement and validation
- Auction timing and deadline enforcement
- Winner selection logic

## Deployment

To deploy the contract:

1. Configure deployment settings (e.g., network, wallet) in your deployment script or tool (such as Hardhat or Truffle).
2. You can deploy in the localhost network following these steps:
   
   Start a local node:
   
   ```bash
   npx hardhat node
   ```
   Open a new terminal and deploy the Hardhat Ignition module in the localhost network:

   ```bash
   npx hardhat ignition deploy ./ignition/modules/Lock.ts --network localhost
   ```

## Contributing

Contributions are welcome! Please open issues and pull requests as needed.

1. Fork the repository.
2. Create a new branch for your feature or bugfix.
3. Commit your changes.
4. Open a pull request describing your changes.

## License

This project is licensed under the [MIT License](LICENSE).

---

**Repository:** [txich/Last-Bid-Auction](https://github.com/txich/Last-Bid-Auction)
