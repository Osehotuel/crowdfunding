// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC20{

    function transfer (address, uint) external returns(bool);
    function transferFrom (address, address, uint) external returns(bool);
}

contract CrowdFund{

    //Create an even named Launch which comprisesof id, creator, goal, StartAt, endAt.


    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );

    event cancel(
        uint id
    );

    event pledge(
        uint indexed id,
        address indexed caller,
        uint amount
    );


/*Classwork

1. Create an event for unpledge which has id, caller, amount.
2. Create an event for Claim which has an id.
3. Create an event for Refund which has an id that is not indexed, caller and amount.*/

    event Unpledge(
        uint indexed id,
        address indexed caller,
        uint amount
    );

    event Claim(
        uint id
    );

    event Refund(
        uint id,
        address indexed caller,
        uint amount
    );


/*Classwork
Create a struct named Campaign that has the following: 
creator, goal, pledged, startAt, endAt and claimed which is a bool*/ 
//Struct allows us create more complicated data types that have multiple properties

    struct Campaign{
        //creator of the campaign 
        address creator;
        uint goal;
        uint pledged;
        uint startAt;
        uint endAt;
        bool claimed;
    }

    IERC20 public immutable token;// making reference to the ERC20 token 
    //(Immuitable means something that won't change, so the token won't change it is also a way of saving gas)

    uint public count;

    mapping(uint => Campaign) public campaigns;

    mapping(uint => mapping(address => uint)) public pledgedAmount; //nested mapping

    constructor (address _token){
        token = IERC20(_token);//
    }

    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external{
        require(_startAt >= block.timestamp, "startAt < now"); 
        require(_endAt >= _startAt, "endAt < startAt");
        require(_endAt <= block.timestamp + 90 days, "endAt > max duration");

        count +=1;

        //create a struct, input the following: msg.sender,goal,0, startAt,endAt and false

       campaigns[count] = Campaign(msg.sender, _goal, 0, _startAt, _endAt,false);
       //campaigns[1] = Campaign(msg.sender, 1000, 0, _startAt, _endAt,false);

       emit Launch(count, msg.sender, _goal, _startAt, _endAt);
    }

        function Cancel(uint _id) external{
            Campaign memory campaign = campaigns[_id];
            require(campaign.creator == msg.sender, "You are not the creator");
            require(block.timestamp < campaign.startAt, "The campaign has started");

            delete campaigns[_id];
            emit cancel (_id);

        }

        function Pledge(uint _id, uint _amount) external{
            Campaign storage campaign = campaigns[_id];
            require(block.timestamp >= campaign.startAt, "Campaign has not started");
            require(block.timestamp <= campaign.endAt, "campaign has ended");
            campaign.pledged += _amount;
            pledgedAmount[_id][msg.sender] +=_amount;
            token.transferFrom(msg.sender,address(this), _amount);
            emit pledge(_id, msg.sender, _amount);

        }

        function unpledge(uint _id, uint _amount) external{
            Campaign storage campaign = campaigns[_id];
            require(block.timestamp <= campaign.endAt, "Campaign has ended");
            campaign.pledged -= _amount;
            pledgedAmount[_id][msg.sender] -=_amount; 
            token.transfer(msg.sender, _amount);
            emit Unpledge(_id, msg.sender, _amount);

        }

        function claim(uint _id) external{
            Campaign storage campaign = campaigns[_id];
            require(campaign.creator == msg.sender, "You are not the owner");
            require(block.timestamp > campaign.endAt, "Campaign has not ended");
            require(campaign.pledged >= campaign.goal, "pledged < goal");
            require(!campaign.claimed, "Campaign has been claimed");

            campaign.claimed = true;
            token.transfer(campaign.creator,campaign.pledged);
            emit Claim(_id);

        }

        function refund(uint _id) external{
            Campaign memory campaign = campaigns[_id];
            require(block.timestamp > campaign.endAt,"It has not ended");
            require(campaign.pledged < campaign.goal, "pledged>=goal");

            uint balance = pledgedAmount[_id][msg.sender];
            pledgedAmount[_id][msg.sender] =0;
            token.transfer(msg.sender, balance);
            emit Refund(_id, msg.sender, balance);

        }

        

    }




