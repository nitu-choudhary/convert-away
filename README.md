# Convert Away DApp

Convert Away DApp is a decentralized application that provides real-time conversion rates of various cryptocurrencies to USD and between different cryptocurrencies. The price information is obtained from ChainLink price feed for Avalanche Fuji Testnet.

- Deployed contract address: `0xBd7AfA95d39F1B5Dbe9D164FeCD1b4394EfEcAD7`
- Deployed DApp Link: [Click here to check out the Convert Away DApp](https://convert-away-dapp.netlify.app/)

## Instructions to run the app
- When using for local testing make sure to add .env file containing the following information
```
QUICKNODE_URL=<your-quicknoe-url>
METAMASK_PRIVATE_KEY=<your-private-key>
VITE_CONTRACT_ADDRESS=<add-the-contract-address-once-compiled-and-deployed-here>
```

- Compile smart contract using the following command after creating .env file with the above information
`yarn hardhat compile`
- Deploy the contract
`yarn hardhat run scripts/deploy.js --network fuji`
- Copy the deployed contract address from your console to the .env file. 
This is the value for variable `VITE_CONTRACT_ADDRESS` in the .env file.
- Run the app using the following command
`yarn dev`

## References for terraform files
Thanks to Cumulus Cycles youtube channel for the terraform videos to help provision ECR/ ECS infra for convert away dapp.

Github repo: https://github.com/CumulusCycles/IaC_on_AWS_with_Terraform/blob/main/src/5_Terraform_ECR_ECS/modules/tf-state/variables.tf

Youtube Video: https://www.youtube.com/watch?v=cgTPxw2oGI8

Terraform + Github actions: https://www.youtube.com/watch?v=scecLqTeP3k