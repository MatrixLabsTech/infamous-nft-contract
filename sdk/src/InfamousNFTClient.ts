import {CollectionInfo, IStakingTime, ITokenId, TokenData} from "./CollectionInfo";
import {WearWeaponEvent, WearWeaponEvents, WearWeaponHistoryItem} from "./WearWeaponInfo";

export interface ITransaction {
    type: string;
    function: string;
    arguments: any[];
    type_arguments: any[];
}
export interface PaginationArgs {
    start?: number;
    limit?: number;
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

    resolveTokenId(tokenName: string): Promise<ITokenId>;
    resolveWeaponTokenId(tokenName: string): Promise<ITokenId>;
    isTokenOwner(addr: string, tokenId: ITokenId): Promise<boolean>;

    // token owned
    tokenOwned(addr: string): Promise<TokenData[]>;

    tokenIdsOwned(addr: string): Promise<ITokenId[]>;

    tokenData(tokenId: ITokenId): Promise<TokenData | undefined>;

    weaponIdsOwned(addr: string): Promise<ITokenId[]>;

    weaponData(weaponTokenName: string): Promise<TokenData | undefined>;

    wearWeaponTotal(tokenId: ITokenId): Promise<WearWeaponEvents | undefined>;
    wearWeaponPage(events: WearWeaponEvents, query?: PaginationArgs): Promise<WearWeaponHistoryItem[]>;

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
