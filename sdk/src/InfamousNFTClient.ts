import {CollectionInfo, IStakingTime, ITokenId, TokenData} from "./CollectionInfo";

export interface ITransaction {
    type: string;
    function: string;
    arguments: any[];
    type_arguments: any[];
}

export interface InfamousNFTClient {
    // package mint trans
    mintTransaction(count: string): ITransaction;
    stakeTransaction(tokenName: string): ITransaction;
    unstakeTransaction(tokenName: string): ITransaction;
    wearWeaponTransaction(tokenName: string, weaponName: string): ITransaction;

    // infamous collection info
    collectionInfo(): Promise<CollectionInfo>;

    // token owned
    tokenOwned(addr: string): Promise<TokenData[]>;

    tokenIdsOwned(addr: string): Promise<ITokenId[]>;

    tokenData(tokenId: ITokenId): Promise<TokenData | undefined>;

    tokenStaked(addr: string): Promise<ITokenId[]>;

    tokenStakeData(tokenId: ITokenId): Promise<IStakingTime | undefined>;

    tokenPerMinted(addr: string): Promise<number>;
}
