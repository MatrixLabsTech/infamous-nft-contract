import {InfamousNFTClient, ITransaction} from "./InfamousNFTClient";

import * as Gen from "aptos/dist/generated";
import {
    tokenStoreResource,
    deployment,
    IDeployment,
    infamousCollectionName,
    weaponCollectionName,
} from "./config/development";
import {IManagerAccountCapability} from "./ManagerAccountCapability";
import {
    CollectionInfo,
    DepositEvent,
    ICollectionStatusInfo,
    IStakingTime,
    ITokenData,
    ITokenId,
    ITokenStore,
    PropertyItem,
    TokenData,
} from "./CollectionInfo";
import {decodeString, decodeU64, paramToHex} from "./utils/param";
import {AptosClient, TokenClient} from "aptos";
import {DEVNET_REST_SERVICE, TESTNET_REST_SERVICE} from "./consts/networks";
import {ITokenStakes, ITokenStakesData} from "./StakingInfo";
import {IWearWeaponInfo, WearWeaponHistoryItem} from "./WearWeaponInfo";
import {IAirdropInfo, IUpgradeInfo} from "./UpgradeInfo";
import {IOpenBoxStatus} from "./OpenBoxStatus";
export enum AptosNetwork {
    Testnet = "Testnet",
    Mainnet = "Mainnet",
    Devnet = "Devnet",
}

export class InfamousNFTClientImpl implements InfamousNFTClient {
    readClient: AptosClient;
    deployment: IDeployment;
    tokenClient: TokenClient;
    manager_addr?: string;
    constructor(network: AptosNetwork = AptosNetwork.Devnet) {
        if (network === AptosNetwork.Testnet) {
            this.readClient = new AptosClient(TESTNET_REST_SERVICE);
            this.deployment = deployment.testnet;
            this.tokenClient = new TokenClient(this.readClient);
        } else {
            this.readClient = new AptosClient(DEVNET_REST_SERVICE);
            this.deployment = deployment.devnet;
            this.tokenClient = new TokenClient(this.readClient);
        }
    }
    mintTransaction(count: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousNft}::mint`,
            arguments: [paramToHex(count, "u64")],
            type_arguments: [],
        };
    }

    stakeTransaction(tokenName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousStake}::stake_infamous_nft_script`,
            arguments: [paramToHex(tokenName, "0x1::string::String")],
            type_arguments: [],
        };
    }

    unstakeTransaction(tokenName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousStake}::unstake_infamous_nft_script`,
            arguments: [paramToHex(tokenName, "0x1::string::String")],
            type_arguments: [],
        };
    }

    upgradeTransaction(tokenName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousUpgradeLevel}::upgrade`,
            arguments: [paramToHex(tokenName, "0x1::string::String")],
            type_arguments: [],
        };
    }

    wearWeaponTransaction(tokenName: string, weaponName: string): ITransaction {
        return {
            type: "entry_function_payload",
            function: `${this.deployment.moduleAddress}::${this.deployment.infamousWeaponWear}::wear_weapon`,
            arguments: [paramToHex(tokenName, "0x1::string::String"), paramToHex(weaponName, "0x1::string::String")],
            type_arguments: [],
        };
    }

    async collectionInfo(): Promise<CollectionInfo> {
        const managerAddress = await this.getManagerAddress();
        const collectionInfo = await this.tokenClient.getCollectionData(managerAddress, infamousCollectionName);
        return collectionInfo;
    }

    async tokenLevel(tokenId: ITokenId): Promise<number> {
        try {
            const upgradeInfo = await this.getUpgradeInfo();
            const info = upgradeInfo.data as IUpgradeInfo;
            const level = await this.tableItem(info.token_level.handle, `0x3::token::TokenId`, `u64`, tokenId);
            return parseInt(level);
        } catch (e) {
            return 0;
        }
    }

    async tokenAirdroped(level: number, tokenId: ITokenId): Promise<ITokenId | undefined> {
        try {
            if (level === 4) {
                const airdropInfo = await this.getAirdropInfo();
                const info = airdropInfo.data as IAirdropInfo;
                const weapon_token_id = await this.tableItem(
                    info.token_level4_airdroped.handle,
                    `0x3::token::TokenId`,
                    `0x3::token::TokenId`,
                    tokenId
                );
                return weapon_token_id;
            } else if (level === 5) {
                const airdropInfo = await this.getAirdropInfo();
                const info = airdropInfo.data as IAirdropInfo;
                const weapon_token_id = await this.tableItem(
                    info.token_level5_airdroped.handle,
                    `0x3::token::TokenId`,
                    `0x3::token::TokenId`,
                    tokenId
                );
                return weapon_token_id;
            }
        } catch (e) {
            return undefined;
        }
        return undefined;
    }

    async tokenIsReveled(tokenId: ITokenId): Promise<boolean> {
        try {
            const openBoxStatus = await this.getOpenBoxStatus();
            const info = openBoxStatus.data as IOpenBoxStatus;
            const reveled = await this.tableItem(info.open_status.handle, `0x3::token::TokenId`, `bool`, tokenId);
            return reveled;
        } catch (e) {
            return false;
        }
    }

    async tokenWearedWeapon(tokenId: ITokenId): Promise<ITokenId | undefined> {
        try {
            const tokenWearWeapon = (await this.getTokenWearWeapon()).data as IWearWeaponInfo;
            const weapoTokenName = await this.tableItem(
                tokenWearWeapon.token_weapon_table.handle,
                `0x3::token::TokenId`,
                `0x1::string::String`,
                tokenId
            );
            if (weapoTokenName) {
                return {
                    property_version: "0",
                    token_data_id: {
                        collection: weaponCollectionName,
                        creator: this.manager_addr || "",
                        name: weapoTokenName,
                    },
                };
            }
            return undefined;
        } catch (e) {
            return undefined;
        }
    }

    async tokenOwned(addr: string): Promise<TokenData[]> {
        try {
            const tokenIds = await this.doResolveTokenOwned(addr, infamousCollectionName);
            const list: TokenData[] = [];
            for (const tokenId of tokenIds) {
                const tokenData = await this.tokenData(tokenId);
                tokenData && list.push(tokenData);
            }
            return list;
        } catch (e) {
            return [];
        }
    }

    async tokenIdsOwned(addr: string): Promise<ITokenId[]> {
        try {
            return await this.doResolveTokenOwned(addr, infamousCollectionName);
        } catch (e) {
            return [];
        }
    }

    async tokenData(tokenId: ITokenId): Promise<TokenData | undefined> {
        try {
            return await this.doGetTokenData(tokenId);
        } catch (e) {}
    }

    async weaponIdsOwned(addr: string): Promise<ITokenId[]> {
        try {
            return await this.doResolveTokenOwned(addr, weaponCollectionName);
        } catch (e) {
            return [];
        }
    }

    async weaponData(weaponTokenName: string): Promise<TokenData | undefined> {
        const managerAddress = await this.getManagerAddress();
        const tokenId: ITokenId = {
            property_version: "0",
            token_data_id: {
                collection: weaponCollectionName,
                creator: managerAddress,
                name: weaponTokenName,
            },
        };

        return await this.tokenData(tokenId);
    }

    async tokenStaked(addr: string): Promise<ITokenId[]> {
        try {
            const stakes = await this.getTokenStakes(addr);
            return (stakes.data as ITokenStakes).staking;
        } catch (e) {
            return [];
        }
    }

    async tokenStakeData(tokenId: ITokenId): Promise<IStakingTime | undefined> {
        const tokenStakeData = await this.getTokenStakeData();
        const data = tokenStakeData.data as ITokenStakesData;
        const stakingTime = await this.tableItem(
            data.staking_time.handle,
            `0x3::token::TokenId`,
            `${this.deployment.moduleAddress}::${this.deployment.infamousStake}::StakingTime`,
            tokenId
        );
        return stakingTime as IStakingTime;
    }

    async tokenPerMinted(addr: string): Promise<number> {
        try {
            const stateResource = await this.getCollectionStatusInfo();
            const collectionStatusInfo = stateResource.data as ICollectionStatusInfo;
            return await this.tableItem(collectionStatusInfo.per_minted_table.handle, "address", "u64", addr);
        } catch (e) {
            return 0;
        }
    }

    async wearWeaponHistory(tokenId?: ITokenId): Promise<WearWeaponHistoryItem[]> {
        try {
            const tokenWearWeapon = (await this.getTokenWearWeapon()).data as IWearWeaponInfo;

            const wearEvents = await this.readClient.getEventsByCreationNumber(
                tokenWearWeapon.weapon_wear_events.guid.id.addr,
                tokenWearWeapon.weapon_wear_events.guid.id.creation_num
            );
            const list = wearEvents.map((e) => e.data as WearWeaponHistoryItem);
            if (tokenId) {
                return list.filter((l) => l.token_id.token_data_id.name === tokenId.token_data_id.name);
            } else {
                return list;
            }
        } catch (e) {
            return [];
        }
    }

    private async getAirdropInfo(): Promise<Gen.MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousBackendTokenWeaponAirdrop}::AirdropInfo`
        );
    }

    private async getUpgradeInfo(): Promise<Gen.MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousUpgradeLevel}::UpgradeInfo`
        );
    }

    private async getOpenBoxStatus(): Promise<Gen.MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousBackendOpenBox}::OpenBoxStatus`
        );
    }

    private async getTokenWearWeapon(): Promise<Gen.MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousWeaponStatus}::TokenWearWeapon`
        );
    }

    private async getTokenStakes(addr: string): Promise<Gen.MoveResource> {
        return await this.readClient.getAccountResource(
            addr,
            `${this.deployment.moduleAddress}::${this.deployment.infamousStake}::TokenStakes`
        );
    }
    private async getTokenStakeData(): Promise<Gen.MoveResource> {
        const managerAddress = await this.getManagerAddress();
        return await this.readClient.getAccountResource(
            managerAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousStake}::TokenStakesData`
        );
    }

    private async doGetTokenData(tokenId: ITokenId): Promise<TokenData> {
        const collection: {type: Gen.MoveStructTag; data: any} = await this.readClient.getAccountResource(
            tokenId.token_data_id.creator,
            "0x3::token::Collections"
        );

        const {handle} = collection.data.token_data;
        const tokenData = (await this.tableItem(
            handle,
            "0x3::token::TokenDataId",
            "0x3::token::TokenData",
            tokenId.token_data_id
        )) as ITokenData;
        const properties: PropertyItem[] = [];
        tokenData.default_properties.map.data.forEach((p) => {
            properties.push({
                key: p.key,
                value: decodeValue(p.value.value, p.value.type),
            });
        });

        return {
            collection: tokenId.token_data_id.collection,
            description: tokenData.description,
            name: tokenData.name,
            maximum: tokenData.maximum,
            supply: tokenData.supply,
            uri: tokenData.uri,
            properties,
        };
    }

    private async doResolveTokenOwned(addr: string, collectionName: string): Promise<ITokenId[]> {
        const managerAddress = await this.getManagerAddress();
        const tokenStore = await this.getTokenStoreInfo(addr);

        let tokenIds: ITokenId[] = [];
        const depositEvents = (await this.readClient.getEventsByCreationNumber(
            tokenStore.data.deposit_events.guid.id.addr,
            tokenStore.data.deposit_events.guid.id.creation_num
        )) as DepositEvent[];
        depositEvents.forEach((e) => {
            if (
                e.data.id.token_data_id.collection === collectionName &&
                e.data.id.token_data_id.creator === managerAddress
            ) {
                tokenIds.push(e.data.id);
            }
        });

        const burnEvents = await this.readClient.getEventsByCreationNumber(
            tokenStore.data.burn_events.guid.id.addr,
            tokenStore.data.burn_events.guid.id.creation_num
        );

        burnEvents.forEach((e) => {
            if (
                e.data.id.token_data_id.collection === collectionName &&
                e.data.id.token_data_id.creator === managerAddress
            ) {
                tokenIds = tokenIds.filter((id) => {
                    return !(
                        id.property_version === e.data.id.property_version &&
                        id.token_data_id.creator === e.data.id.token_data_id.creator &&
                        id.token_data_id.name === e.data.id.token_data_id.name
                    );
                });
            }
        });

        const withdrawEvents = await this.readClient.getEventsByCreationNumber(
            tokenStore.data.withdraw_events.guid.id.addr,
            tokenStore.data.withdraw_events.guid.id.creation_num
        );

        withdrawEvents.forEach((e) => {
            if (
                e.data.id.token_data_id.collection === collectionName &&
                e.data.id.token_data_id.creator === managerAddress
            ) {
                const existIndex = tokenIds.findIndex(
                    (id) =>
                        id.property_version === e.data.id.property_version &&
                        id.token_data_id.creator === e.data.id.token_data_id.creator &&
                        id.token_data_id.name === e.data.id.token_data_id.name
                );
                if (existIndex > -1) tokenIds = tokenIds.filter((_, index) => index !== existIndex);
            }
        });
        return tokenIds;
    }

    private async getCollectionStatusInfo(): Promise<Gen.MoveResource> {
        return await this.readClient.getAccountResource(
            this.deployment.moduleAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousNft}::CollectionInfo`
        );
    }

    private async getManagerAddress(): Promise<string> {
        if (this.manager_addr) {
            return this.manager_addr;
        }
        const managerAccountCapability = await this.getManagerAccountCapability();
        if (managerAccountCapability) {
            const info = managerAccountCapability.data as IManagerAccountCapability;
            this.manager_addr = info.signer_cap.account;
            return this.manager_addr;
        } else {
            throw new Error("ManagerAccountCapability not found");
        }
    }

    private async getTokenStoreInfo(addr: string): Promise<ITokenStore> {
        const tokenStore = await this.readClient.getAccountResource(addr, tokenStoreResource);
        return tokenStore as ITokenStore;
    }

    private async getManagerAccountCapability(): Promise<Gen.MoveResource> {
        return await this.readClient.getAccountResource(
            this.deployment.moduleAddress,
            `${this.deployment.moduleAddress}::${this.deployment.infamousManagerCap}::ManagerAccountCapability`
        );
    }

    private async tableItem(handle: string, keyType: string, valueType: string, key: any): Promise<any> {
        const getTokenTableItemRequest = {
            key_type: keyType,
            value_type: valueType,
            key,
        };

        return this.readClient.getTableItem(handle, getTokenTableItemRequest);
    }
}

export function decodeValue(value: string, type: string): string {
    if (type === "u64") {
        return decodeU64(value).toString();
    }
    if (type === "0x1::string::String") {
        return decodeString(value);
    }
    return value;
}
