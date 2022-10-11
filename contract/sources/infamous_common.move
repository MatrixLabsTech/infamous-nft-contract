module infamous::infamous_common {

    use std::string::{Self, String};
    use std::vector;

    public fun infamous_collection_name(): String {
        string::utf8(b"InfamousNFT")
    }

    public fun infamous_collection_uri(): String {
        string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/infamous_collection_name.png")
    }

    public fun infamous_base_token_name(): String {
        string::utf8(b"Infamous #")
    }

    
    public fun infamous_base_token_uri(): String {
        string::utf8(b"https://beta.api.infamousnft.xyz/infamousnft/token/")
    }

    public fun infamous_description(): String {
        string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs")
    }

    public fun infamous_level_key(): String {
        string::utf8(b"level")
    }

    public fun infamous_weapon_key(): String {
        string::utf8(b"weapon")
    }


    
    public fun infamous_weapon_collection_name(): String {
        string::utf8(b"InfamousWeaponNFT")
    }

    public fun infamous_weapon_collection_uri(): String {
        string::utf8(b"https://d39njnv5mk7be5.cloudfront.net/static/infamous_collection_name.png")
    }

    public fun infamous_weapon_base_token_name(): String {
        string::utf8(b"InfamousWeaponNFT #")
    }

    
    public fun infamous_weapon_base_token_uri(): String {
        string::utf8(b"https://beta.api.infamousnft.xyz/infamousnft/token/")
    }

    public fun infamous_weapon_description(): String {
        string::utf8(b"Infamous (NFMS) is the first gamified dynamic NFT project being built on the Aptos blockchain. Powered by MatrixLabs")
    }

    /// Helper to append number to string
    public fun append_num(base_str: String, num: u64): String {
        let str = copy base_str;
        string::append(&mut str, num_str(num));
        str
    }

    public fun num_str(num: u64): String{
        let v1 = vector::empty();
        while (num/10 > 0){
            let rem = num%10;
            vector::push_back(&mut v1, (rem+48 as u8));
            num = num/10;
        };
        vector::push_back(&mut v1, (num+48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }

 
    
    /// Helper to remove an element from a vector.
    public fun remove_element<E: drop>(v: &mut vector<E>, x: &E) {
        let (found, index) = vector::index_of(v, x);
        if (found) {
            vector::remove(v, index);
        }
    }

    public fun add_element<E: drop>(v: &mut vector<E>, x: E) {
        if (!vector::contains(v, &x)) {
            vector::push_back(v, x)
        }
    }

  
}
