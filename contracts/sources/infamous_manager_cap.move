/// This module provides an resource account capability for all modules.
module infamous::infamous_manager_cap {

    use std::error;
    use std::string;
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::timestamp;

    use infamous::infamous_common;

    friend infamous::infamous_nft;
    friend infamous::infamous_lock;
    friend infamous::infamous_upgrade_level;
    friend infamous::infamous_backend_open_box;
    friend infamous::infamous_properties_url_encode_map;

    friend infamous::infamous_weapon_nft;
    friend infamous::infamous_weapon_status;

    friend infamous::infamous_weapon_wear;
    friend infamous::infamous_backend_token_weapon_airdrop;

    const EMANAGER_ACCOUNT_INFO_NOT_PUBLISHED: u64 = 1;

    struct ManagerAccountCapability has key { signer_cap: SignerCapability }


    fun init_module(source: &signer) {
        let registry_seed = infamous_common::u128_to_string((timestamp::now_microseconds() as u128));
        string::append(&mut registry_seed, string::utf8(b"registry_seed"));
        let (_, resource_signer_cap) = account::create_resource_account(source, *string::bytes(&registry_seed));
        move_to(source, ManagerAccountCapability {
            signer_cap: resource_signer_cap
        });
    }


    public(friend) fun get_manager_signer(): signer acquires ManagerAccountCapability {
        let source_addr = @infamous;
        assert!(exists<ManagerAccountCapability>(source_addr), error::not_found(EMANAGER_ACCOUNT_INFO_NOT_PUBLISHED));
        let manager_account_capability = borrow_global<ManagerAccountCapability>(source_addr);
        account::create_signer_with_capability(&manager_account_capability.signer_cap)
    }

    #[test_only]
    public fun initialize(user: &signer) {
        init_module(user);
    }


    #[test(user = @infamous, framework = @0x1, )]
    public fun end_to_end(user: &signer, framework:&signer) acquires ManagerAccountCapability {

        use std::signer;
        use aptos_std::debug;
        timestamp::set_time_has_started_for_testing(framework);

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        init_module(user);

        let manager_signer = get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        debug::print<address>(&manager_addr);
    }


}
