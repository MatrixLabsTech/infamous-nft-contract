export const collectionResource = `0x3::token::Collections`;
export const tokenStoreResource = `0x3::token::TokenStore`;
export const collectionName = "InfamousNFT";

export interface IDeployment {
    moduleAddress: string;
    creator: string;
    nftModuleName: string;
    managerCapModuleName: string;
    version: number;
}

export const deployment = {
    testnet: {
        moduleAddress: "0xd8cf3661a4d4fbd933623933075babf3bbbca109331658e83d040b056986bf9",
        creator: "0xd8cf3661a4d4fbd933623933075babf3bbbca109331658e83d040b056986bf9",
        nftModuleName: "infamous_nft",
        managerCapModuleName: "manager_cap",
        version: 15783525,
    },
    devnet: {
        moduleAddress: "0xd8cf3661a4d4fbd933623933075babf3bbbca109331658e83d040b056986bf9",
        creator: "0xd8cf3661a4d4fbd933623933075babf3bbbca109331658e83d040b056986bf9",
        nftModuleName: "infamous_nft",
        managerCapModuleName: "manager_cap",
        version: 15783525,
    },
};
