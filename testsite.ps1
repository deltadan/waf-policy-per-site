# Test Site

$pip = Get-AzPublicIPAddress -ResourceGroupName myResourceGroup4AG -Name myAGPublicIPAddress


#should be blocked
curl 52.152.247.9/globalBlock
curl 52.152.247.9/?1=1

#should be allowed
curl 52.152.247.9/globalAllow?1=1

#should be blocked
curl 52.152.247.9:8080/siteBlock
curl 52.152.247.9/?1=1

#should be allowed
curl 52.152.247.9:8080/siteAllow?1=1

#should be blocked
curl 52.152.247.9/URIBlock
curl 52.152.247.9/?1=1

#should be allowed
curl 52.152.247.9/URIAllow?1=1