import {InfamousNFTClient, ITransaction} from "./InfamousNFTClient";

import * as Gen from "aptos/dist/generated";
import {tokenStoreResource, collectionName, deployment, IDeployment} from "./config/development";
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
import {decodeU64, paramToHex} from "./utils/param";
import {AptosClient, TokenClient} from "aptos";
import {DEVNET_REST_SERVICE, TESTNET_REST_SERVICE} from "./consts/networks";
import {ITokenStakes, ITokenStakesData} from "./StakingInfo";
import {Deserializer} from "aptos/dist/transaction_builder/bcs/deserializer";
export enum AptosNetwork {
    Testnet = "Testnet",
    Mainnet = "Mainnet",
    Devnet = "Devnet",
}

export class InfamousNFTClientImpl implements InfamousNFTClient {
    readClient: AptosClient;
    deployment: IDeployment;
    tokenClient: TokenClient;
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
        const collectionInfo = await this.tokenClient.getCollectionData(managerAddress, collectionName);
        return collectionInfo;
    }

    async tokenOwned(addr: string): Promise<TokenData[]> {
        try {
            const tokenIds = await this.doResolveTokenOwned(addr);
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
            return await this.doResolveTokenOwned(addr);
        } catch (e) {
            return [];
        }
    }

    async tokenData(tokenId: ITokenId): Promise<TokenData | undefined> {
        try {
            return await this.doGetTokenData(tokenId);
        } catch (e) {}
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

    private async doResolveTokenOwned(addr: string): Promise<ITokenId[]> {
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
        const managerAccountCapability = await this.getManagerAccountCapability();
        if (managerAccountCapability) {
            const info = managerAccountCapability.data as IManagerAccountCapability;
            return info.signer_cap.account;
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
    return value;
}
