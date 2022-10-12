import {AptosClient} from "aptos";
import {IDeployment} from "./config/development";

export class StakeClient {
    client: AptosClient;
    constructor(client: AptosClient) {
        this.client = client;
    }

    // private async getTokenStakes(addr: string): Promise<Gen.MoveResource> {
    //     return await this.client.getAccountResource(
    //         addr,
    //         `${this.deployment.moduleAddress}::${this.deployment.infamousStake}::TokenStakes`
    //     );
    // }
}
