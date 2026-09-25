import copy,json,pathlib,subprocess,sys
catalog={name:json.loads(pathlib.Path(f'assets/data/{name}.json').read_text()) for name in ['generators','upgrades','achievements','bosses','enemies']}
p=subprocess.Popen([str(pathlib.Path(sys.argv[1]).resolve())],stdin=subprocess.PIPE,stdout=subprocess.PIPE,text=True)
checks=0
def check(data,want):
 global checks
 checks+=1;p.stdin.write(json.dumps({'catalog':data})+'\n');p.stdin.flush();result=json.loads(p.stdout.readline());assert result.get('ok')==want,result
try:
 check(catalog,True)
 normalized=copy.deepcopy(catalog)
 for upgrade in normalized['upgrades']:
  for condition in upgrade['unlockConditions']:
   if condition['type']=='upgrade': condition['target']=condition.pop('id')
 check(normalized,True)
 def bad(path,value):
  data=copy.deepcopy(catalog);item=data
  for key in path[:-1]: item=item[key]
  item[path[-1]]=value;check(data,False)
 bad(['generators','tadpole','baseCost'],0)
 bad(['generators','tadpole','baseProduction'],'0.1')
 bad(['generators','tadpole','enabled'],'true')
 bad(['generators','tadpole','id'],'froglet')
 bad(['generators','tadpole','unlockRequirements',0,'type'],'unsupported')
 bad(['generators','tadpole','count'],.5)
 bad(['generators','tadpole','boosts'],[{'id':'bad','source':'custom','multiplier':-1,'active':True}])
 bad(['upgrades',0,'unlockConditions'],[{'type':'upgrade','target':'missing'}])
 bad(['upgrades',0,'cost'],-1)
 bad(['upgrades',1,'id'],catalog['upgrades'][0]['id'])
 bad(['upgrades',0,'effects',0,'multiplier'],0)
 bad(['upgrades',0,'unlockConditions'],[{'type':'upgrade','id':'missing'}])
 bad(['upgrades',0,'unlockConditions'],[{'type':'totalBufos','value':'50'}])
 bad(['achievements',0,'requirement','type'],'unsupported')
 bad(['achievements',0,'reward','value'],-1)
 bad(['bosses',1,'threshold'],catalog['bosses'][0]['threshold'])
 bad(['bosses',0,'baseHealth'],0)
 bad(['enemies','BASE_DROP_ITEMS','common_slime','dropRate'],2)
 bad(['enemies','INITIAL_ENEMY_TEMPLATES',0,'typeWeights'],[1])
 bad(['enemies','INITIAL_ENEMY_TEMPLATES',0,'typeWeights'],[0,0])
 bad(['enemies','INITIAL_ENEMY_TEMPLATES',0,'areas'],['Missing'])
 bad(['enemies','INITIAL_ENEMY_TEMPLATES',0,'baseDropTable','possibleDrops',0,'id'],'missing')
 print(f'Catalog validation passed: {checks} valid/invalid startup catalogs')
finally:p.stdin.close();assert p.wait(timeout=10)==0
