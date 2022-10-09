module infamous::manager_cap {

    use std::error;
    use aptos_framework::account::{Self, SignerCapability};

    friend infamous::infamous_nft;

    const EMANAGER_ACCOUNT_INFO_NOT_PUBLISHED: u64 = 1;

    struct ManagerAccountCapability has key { signer_cap: SignerCapability }


    fun init_module(source: &signer) {
        let seed = x"01";
        let (_, resource_signer_cap) = account::create_resource_account(source, seed);
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


    #[test(user = @infamous)]
    public fun end_to_end(user: &signer) acquires ManagerAccountCapability {

        use std::signer;
        use aptos_std::debug;

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        init_module(user);

        let manager_signer = get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        debug::print<address>(&manager_addr);
    }


}
