dofile('locales/nl.lua'); dofile('locale.lua')
local ownLocale = Locales.nl
 dofile('../ts_bridge/locales/nl.lua')
 for key, value in pairs(ownLocale) do Locales.nl[key] = value end
TSBridgeGuard={Await=function() return true end,IsReady=function() return true end}
local funds, treasury, cards, full, addFailure, uncertainCredit, mode, observedAccount = 100,200,0,false,false,false,nil,nil
local returned, withdrawn = 0,0
local owner={identifier='license:test',job={name='police',grade=0}}
local api={}
function api:GetPlayerData() return owner end
function api:GetSocietyBalance() return treasury,'society_police' end
function api:GetMoney(_,account) observedAccount=account;return funds end
function api:CanCarryItem() return not full end
function api:RemoveMoney(_,account,n)
 observedAccount=account; funds=funds-n;withdrawn=withdrawn+1
 return {ok=true,uncertain=false}
end
function api:AddMoney(_,account,n) observedAccount=account;funds=funds+n;returned=returned+1;return {ok=true,uncertain=false} end
function api:AddSocietyMoney(key,n)
 assert(key=='society_police')
 if uncertainCredit then return {ok=false,uncertain=true} end
 if mode=='reject' then return {ok=false,uncertain=false} end
 treasury=treasury+n;return {ok=true,uncertain=false}
end
function api:RemoveSocietyMoney(key,n) treasury=treasury-n;return {ok=true,uncertain=false} end
function api:AddItem(_,item,n,metadata)
 assert(item=='politie_sleutelkaart' and metadata.tsKeycardTransaction)
 if addFailure then return false,'inventory_full' end
 cards=cards+1;return true
end
exports={ts_bridge=api}
Config={CardPrice=10,FreeCardMinimumGrade=7,Item='politie_sleutelkaart',SocietyAccount='police',PaymentAccount='cash'}
function GetGameTimer() return 100 end
dofile('server/payment.lua')
local function issue(free) return KeycardPayment.issue(owner,1,{ownerName='Test'},free) end
assert(issue().ok and funds==90 and treasury==210 and cards==1 and observedAccount=='cash')
Config.PaymentAccount='bank';assert(issue().ok and funds==80 and treasury==220 and observedAccount=='bank')
full=true;local r=issue();assert(not r.ok and funds==80 and treasury==220);full=false
addFailure=true;r=issue();assert(not r.ok and funds==80 and treasury==220 and cards==2 and returned==1);addFailure=false
mode='reject';r=issue();assert(not r.ok and funds==80 and treasury==220 and returned==2);mode=nil
uncertainCredit=true;r=issue();assert(not r.ok and funds==70 and treasury==220 and returned==2 and r.message:find('beheerder'));uncertainCredit=false
assert(not KeycardPayment.busy, 'lock released after failure')
assert(issue(true).ok and funds==70 and treasury==220 and cards==3)
owner.job.grade=7;assert(issue().ok and funds==70 and cards==4)
owner.job.grade=0;funds=0;r=issue();assert(not r.ok and cards==4)
Config.PaymentAccount='invoice';assert(not issue().ok)
print('PASS: cash/bank card purchase, capacity, rollback, uncertain mutation, free replacements, grade and funds')
