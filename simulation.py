roundCumu=0
roundA=0;
playerCumus=[]
# lpid=0
playerA=[]
lastAPrice=1000000000000000
playerDivi=[]

def AKeysAlg(amount):
    ret=0
    global lastAPrice
    step=(amount/lastAPrice)/10;
    if step<1:
        step=1
    rise=step*18
    while amount-lastAPrice*step >= 1:
        amount=amount-lastAPrice*step
        lastAPrice=lastAPrice*(100000+rise)/100000
        ret=ret+step
    if amount>(lastAPrice*(100000+rise)/100000)/2:
        ret=ret+step
        lastAPrice=lastAPrice*(100000+rise)/100000
    if ret<1:
        lastAPrice=lastAPrice*(100018)/100000
    # print("price", lastAPrice)
    print("keysAlg", ret)
    return ret
    
def  AKeys(amount):
    ret=0
    global lastAPrice
    while amount>0:
        amount=amount-lastAPrice*100018/100000
        lastAPrice=lastAPrice*100018/100000
        ret+=1
    # print("price", lastAPrice)
    print("keys", ret)
    return ret


def calcDiviAlg(pid):
    return roundCumu*playerA[pid]-playerCumus[pid]
    
def updateCumus(pid,amount,keys):
    amount=amount*40/100
    ppt=0
    global roundA
    if(roundA>0):
        ppt=amount/roundA
    global roundCumu
    global playerCumus
    roundCumu=roundCumu+ppt
    pearn=ppt*keys
    if(pid>=len(playerCumus)):
        playerCumus.append(roundCumu*keys-pearn)
    else:
        playerCumus[pid]=(roundCumu*keys-pearn)+playerCumus[pid]
    
def distribute(amount, pid):
    global playerDivi
    amount=amount*40/100
    for x in range(0, len(playerDivi)):
        # if x==pid: continue
        # print("divi",playerDivi[x])
        playerDivi[x]=playerDivi[x]+amount*playerA[x]/roundA
        

def payAlg(pid, amount):
    global roundA
    keys=AKeysAlg(amount)
    roundA+=keys
    global playerA
    if(pid>=len(playerA)):
        playerA.append(keys)
    else:
        playerA[pid]=playerA[pid]+keys
    updateCumus(pid,amount,keys)
    
def pay(pid, amount):
    global playerDivi
    keys=AKeys(amount)
    if(pid>=len(playerDivi)):
        playerDivi.append(0)
        playerA.append(keys)
    else:
        playerA[pid]=playerA[pid]+keys
    global roundA
    roundA=roundA+keys
    distribute(amount, pid)
    
    
    
print("approx:\n")    
payAlg(0,10000000000000000)
payAlg(1,20000000000000000)
payAlg(0,30000000000000000)
payAlg(2,10000000000000000)
payAlg(3,100000000000000000)
payAlg(1,10000000000000000)
payAlg(4,60000000000000000)
payAlg(5,1000000000000000000)
payAlg(3,10000000000000000)
payAlg(4,100000000000000000)
payAlg(6,10000000000000000000)
payAlg(7,20000000000000000)
payAlg(8,100000000000000000)
payAlg(4,50000000000000000)
payAlg(2,100000000000000000)
payAlg(6,7000000000000000)
payAlg(9,10000000000000000)
payAlg(10,1000000000000000000)
payAlg(9,80000000000000000)
payAlg(8,100000000000000000)
com=12817000000000000000*0.4
out=0
for x in range(0, len(playerA)):
    y=calcDiviAlg(x)
    out+=y
    print ("player", x, y)
print("\nleftover:",com-out)

print("-----------------------------------------------------------------------------------\n")
print("no approx:\n")

roundCumu=0
roundA=0;
playerCumus=[]
playerA=[]
lastAPrice=1000000000000000
playerDivi=[]
pay(0,10000000000000000)
pay(1,20000000000000000)
pay(0,30000000000000000)
pay(2,10000000000000000)
pay(3,100000000000000000)
pay(1,10000000000000000)
pay(4,60000000000000000)
pay(5,1000000000000000000)
pay(3,10000000000000000)
pay(4,100000000000000000)
pay(6,10000000000000000000)
pay(7,20000000000000000)
pay(8,100000000000000000)
pay(4,50000000000000000)
pay(2,100000000000000000)
pay(6,7000000000000000)
pay(9,10000000000000000)
pay(10,1000000000000000000)
pay(9,80000000000000000)
pay(8,100000000000000000)
com=12817000000000000000*0.4
out=0
for x in range(0, len(playerDivi)):
    out+=playerDivi[x]
    print ("player", x, playerDivi[x])
print("\nleftover:", com-out)
