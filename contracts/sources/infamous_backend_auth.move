/// This module provides the auth control for backend auth.
module infamous::infamous_backend_auth {

    use std::error;
    use std::signer;
    use std::vector;


    use infamous::infamous_common;

    const ESETACCOUNT_MUSTBE_MODULE_OWNER: u64 = 1;

    /// origin address 1 -> n the address of account who can call the update
    struct CapabilityState has key {
        store: vector<address>,
    }


    public entry fun delegate(origin: &signer, addr: address) acquires CapabilityState {
        let source_addr = @infamous;
        let origin_addr = signer::address_of(origin);
        assert!(source_addr == origin_addr, error::unauthenticated(ESETACCOUNT_MUSTBE_MODULE_OWNER));

        if (!exists<CapabilityState>(source_addr)) {
            move_to(origin, CapabilityState { store: vector::empty() })
        };
        infamous_common::add_element(&mut borrow_global_mut<CapabilityState>(origin_addr).store, addr);
    }

    public entry fun revoke(origin: &signer, addr: address) acquires CapabilityState {
        let source_addr = @infamous;
        let origin_addr = signer::address_of(origin);
        assert!(source_addr == origin_addr, error::unauthenticated(ESETACCOUNT_MUSTBE_MODULE_OWNER));
        if (exists<CapabilityState>(origin_addr)) {
            infamous_common::remove_element(&mut borrow_global_mut<CapabilityState>(origin_addr).store, &addr);
        };
    }

    public fun has_capability(addr: address): bool acquires CapabilityState {
        let source_addr = @infamous;
        let has_flag = false;
        if(source_addr == addr) {
            has_flag = true;
        } else if(exists<CapabilityState>(source_addr)) {
            let capability_state = borrow_global<CapabilityState>(source_addr);
            has_flag = vector::contains(&capability_state.store, &addr);
        };
        has_flag
    }

    #[test(source = @infamous, user = @0xBB)]
    public fun test_auth(source: &signer, user: &signer) acquires CapabilityState { 

        use aptos_framework::account;

        let source_addr = signer::address_of(source);
        account::create_account_for_test(source_addr);

        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);


        assert!(!has_capability(user_addr), 1);

        delegate(source, user_addr);

        assert!(has_capability(user_addr), 1);

        revoke(source, user_addr);

        
        assert!(!has_capability(user_addr), 1);



        
    }

}
