import {CollectionInfo, ITokenDataId} from "./CollectionInfo";

export interface ITransaction {
    type: string;
    function: string;
    arguments: any[];
    type_arguments: any[];
}

export interface InfamousNFTClient {
    mintTransaction(count: string): ITransaction;

    collectionInfo(): Promise<CollectionInfo>;

    tokenOwned(addr: string): Promise<ITokenDataId[]>;
}
