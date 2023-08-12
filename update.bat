set t = %date:~0,4%%date:~5,2%%date:~8,2%0%time:~1,1%%time:~3,2%%time:~6,2%
git add -A 
git commit -m t  
git push origin master