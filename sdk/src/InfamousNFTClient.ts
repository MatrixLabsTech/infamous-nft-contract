import {CollectionInfo, IStakingTime, ITokenId, TokenData} from "./CollectionInfo";
import {WearWeaponEvent, WearWeaponHistoryItem} from "./WearWeaponInfo";

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
    upgradeTransaction(tokenName: string): ITransaction;
    wearWeaponTransaction(tokenName: string, weaponName: string): ITransaction;

    // infamous collection info
    collectionInfo(): Promise<CollectionInfo>;

    // token owned
    tokenOwned(addr: string): Promise<TokenData[]>;

    tokenIdsOwned(addr: string): Promise<ITokenId[]>;

    tokenData(tokenId: ITokenId): Promise<TokenData | undefined>;

    weaponIdsOwned(addr: string): Promise<ITokenId[]>;

    weaponData(weaponTokenName: string): Promise<TokenData | undefined>;

    wearWeaponHistory(tokenId?: ITokenId): Promise<WearWeaponHistoryItem[]>;

    tokenStaked(addr: string): Promise<ITokenId[]>;

    tokenStakeData(tokenId: ITokenId): Promise<IStakingTime | undefined>;

    tokenPerMinted(addr: string): Promise<number>;

    // token level
    tokenLevel(tokenId: ITokenId): Promise<number>;
    // token reveled
    tokenIsReveled(tokenId: ITokenId): Promise<boolean>;

    tokenAirdroped(level: number, tokenId: ITokenId): Promise<ITokenId | undefined>;

    tokenWearedWeapon(tokenId: ITokenId): Promise<ITokenId | undefined>;
}
