APPNAME="cat"
PODNAME=`kubectl -n demo get pods -l "run=$APPNAME" | grep -v NAME|head -1|awk '{print $1'}`
APPNAME=${APPNAME^^}
sed "s/APPNAME/$APPNAME/g" template.html > index.html
kubectl cp index.html $PODNAME:/usr/share/nginx/html/index.html -c $PODNAME

APPNAME="capybara"
PODNAME=`kubectl -n demo get pods -l "run=$APPNAME" | grep -v NAME|head -1|awk '{print $1'}`
APPNAME=${APPNAME^^}
sed "s/APPNAME/$APPNAME/g" template.html > index.html
kubectl cp index.html $PODNAME:/usr/share/nginx/html/index.html -c $PODNAME

APPNAME="apple"
PODNAME=`kubectl -n demo get pods -l "run=$APPNAME" | grep -v NAME|head -1|awk '{print $1'}`
APPNAME=${APPNAME^^}
sed "s/APPNAME/$APPNAME/g" template.html > index.html
kubectl cp index.html $PODNAME:/usr/share/nginx/html/index.html -c $PODNAME

APPNAME="banana"
PODNAME=`kubectl -n demo get pods -l "run=$APPNAME" | grep -v NAME|head -1|awk '{print $1'}`
APPNAME=${APPNAME^^}
sed "s/APPNAME/$APPNAME/g" template.html > index.html
kubectl cp index.html $PODNAME:/usr/share/nginx/html/index.html -c $PODNAME

APPNAME="car"
PODNAME=`kubectl -n demo get pods -l "run=$APPNAME" | grep -v NAME|head -1|awk '{print $1'}`
APPNAME=${APPNAME^^}
sed "s/APPNAME/$APPNAME/g" template.html > index.html
kubectl cp index.html $PODNAME:/usr/share/nginx/html/index.html -c $PODNAME

APPNAME="motobike"
PODNAME=`kubectl -n demo get pods -l "run=$APPNAME" | grep -v NAME|head -1|awk '{print $1'}`
APPNAME=${APPNAME^^}
sed "s/APPNAME/$APPNAME/g" template.html > index.html
kubectl cp index.html $PODNAME:/usr/share/nginx/html/index.html -c $PODNAME