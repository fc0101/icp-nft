import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import List "mo:base/List";
import Array "mo:base/Array";
import Option "mo:base/Option";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Types "./types";

shared actor class Dip721NFT(custodian: Principal, init : Types.Dip721NonFungibleToken) = Self {
  stable var transactionId: Types.TransactionId = 0;
  stable var nfts = List.nil<Types.Nft>();
  stable var custodians = List.make<Principal>(custodian);
  stable var logo : Types.LogoResult = init.logo;
  stable var name : Text = init.name;
  stable var symbol : Text = init.symbol;
  stable var maxLimit : Nat16 = init.maxLimit;

  // https://forum.dfinity.org/t/is-there-any-address-0-equivalent-at-dfinity-motoko/5445/3
  let null_address : Principal = Principal.fromText("aaaaa-aa");

  public query func balanceOfDip721(user: Principal) : async Nat64 {
    return Nat64.fromNat(
      List.size(
        List.filter(nfts, func(token: Types.Nft) : Bool { token.owner == user })
      )
    );
  };

  public query func getCustodians() : async Types.Result<List.List<Principal>, Types.ApiError> {
    return #Ok(custodians);
  };


  public query func ownerOfDip721(token_id: Types.TokenId) : async Types.OwnerResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case (null) {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.owner);
      };
    };
  };

  public shared({ caller }) func safeTransferFromDip721(from: Principal, to: Principal, token_id: Types.TokenId) : async Types.TxReceipt {  
    if (to == null_address) {
      return #Err(#ZeroAddress);
    } else {
      return transferFrom(from, to, token_id, caller);
    };
  };

  public shared({ caller }) func transferFromDip721(from: Principal, to: Principal, token_id: Types.TokenId) : async Types.TxReceipt {
    return transferFrom(from, to, token_id, caller);
  };

  func transferFrom(from: Principal, to: Principal, token_id: Types.TokenId, caller: Principal) : Types.TxReceipt {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        // if (
        //   caller != token.owner and
        //   not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })
        // ) {
        //   return #Err(#Unauthorized);
        // } else if (Principal.notEqual(from, token.owner)) {
        //   return #Err(#Other);
        // } else {
          nfts := List.map(nfts, func (item : Types.Nft) : Types.Nft {
            if (item.id == token.id) {
              let update : Types.Nft = {
                owner = to;
                id = item.id;
                metadata = token.metadata;
              };
              return update;
            } else {
              return item;
            };
          });
          transactionId += 1;
          return #Ok(transactionId);   
        // };
      };
    };
  };

  public query func supportedInterfacesDip721() : async [Types.InterfaceId] {
    return [#TransferNotification, #Burn, #Mint];
  };

  public query func logoDip721() : async Types.LogoResult {
    return logo;
  };

  public query func nameDip721() : async Text {
    return name;
  };

  public query func symbolDip721() : async Text {
    return symbol;
  };

  public query func totalSupplyDip721() : async Nat64 {
    return Nat64.fromNat(
      List.size(nfts)
    );
  };

  public query func getMetadataDip721(token_id: Types.TokenId) : async Types.MetadataResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.id == token_id });
    switch (item) {
      case null {
        return #Err(#InvalidTokenId);
      };
      case (?token) {
        return #Ok(token.metadata);
      }
    };
  };

  public query func getMaxLimitDip721() : async Nat16 {
    return maxLimit;
  };

  public func getMetadataForUserDip721(user: Principal) : async Types.ExtendedMetadataResult {
    let item = List.find(nfts, func(token: Types.Nft) : Bool { token.owner == user });
    switch (item) {
      case null {
        return #Err(#Other);
      };
      case (?token) {
        return #Ok({
          metadata_desc = token.metadata;
          token_id = token.id;
        });
      }
    };
  };

  public query func getTokenIdsForUserDip721(user: Principal) : async [Types.TokenId] {
    let items = List.filter(nfts, func(token: Types.Nft) : Bool { token.owner == user });
    let tokenIds = List.map(items, func (item : Types.Nft) : Types.TokenId { item.id });
    return List.toArray(tokenIds);
  };

  public shared({ }) func mintDip721(to: Principal, name: Text, url: Text) : async Types.MintReceipt {
    // if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
    //   return #Err(#Unauthorized);
    // };
    let result = mint(to, name, url);
    return #Ok(result);
  };

  public shared({ caller }) func mint_multiple (names: Types.Names, to: Principal, url : Types.Url) : async Types.Result<List.List<Types.MintReceiptPart>, Types.ApiError> {
    if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Unauthorized);
    };
    var multi_result = List.nil<Types.MintReceiptPart>();

    for (name in names.vals()) {
      let result : Types.MintReceiptPart = mint(to, name, url);

      multi_result := List.push(result, multi_result);
    };


    return #Ok(multi_result);
  };


  func mint(to: Principal, name: Text, url: Text) : Types.MintReceiptPart {
    let newId = Nat64.fromNat(List.size(nfts));

    let meta_name: Types.MetadataKeyVal = {    
        key = "name";
        val = #TextContent(name);
    };

    let meta_image: Types.MetadataKeyVal = {    
        key = "image_url";
        val = #TextContent(url);
    };


    let metadata:Types.MetadataDesc = [{
      purpose = #Rendered();
      key_val_data = [meta_name, meta_image];
      data:Blob = "1";
    }];


    let nft : Types.Nft = {
      owner = to;
      id = newId;
      metadata = metadata;
    };

    nfts := List.push(nft, nfts);

    transactionId += 1;

    return {
      token_id = newId;
      id = transactionId;
    };
  };


  public shared({ caller }) func mint_multiple_with_addresses (data: Types.MultiMintAdressName, url : Types.Url) : async Types.Result<List.List<Types.MintReceiptPart>, Types.ApiError> {
    if (not List.some(custodians, func (custodian : Principal) : Bool { custodian == caller })) {
      return #Err(#Unauthorized);
    };
    var multi_result = List.nil<Types.MintReceiptPart>();

    for (row in data.vals()) {
      let result : Types.MintReceiptPart = mint(row.address, row.name, url);
      multi_result := List.push(result, multi_result);
    };


    return #Ok(multi_result);
  };
}
