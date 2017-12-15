ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data-unstable"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� ͫ3Z �=KlIv�lv��A�'3�X��R��dw�'ң��I�L��(ydǫivɖ�������^�%�I	0� � �9�l� 2��r�%A�yU�$�eɶ,g`0f���{�^�_}�G5�lG�k��X�<hۦg��AW�t>���J%�o<-��_Z�B��DZL���%^H���%ğ���qe�K�-j��p��C�!��4��x��lj
v����v��_�+k������Vڨu�6�u�u����T��Z��:%Bt}�_��뜁ݞi�V�dOw ��6d}�m��=�{Ӳ�&��ܴ5%����|Іع� 6�N'O�(#�O '$�	%ϝ��-���O�����9t��'�\ �/�����8��Q?�55#֔�瘞�`^������M|-<?�I[�{[���|���Y��kא�S�)�����m��[,��+/��[4�.��]G��e��'� �0 1�j�Tߴ��e���X�U�gH�^���z�S�_�Vb�bB��4�"/s����nE-�P\H
�ۑ]t��5ʆ�l�51Tbd{���qR�p�N�kZ7nrO9�*�,�P�
!�A�'79����
`���p=�CP��a�c���#��8N'��5�S�����T�Q�|R�\K��$q9H]<�z�rH�,d�.�Q�E�>#R\	�J�f���Àb$1BeV3�C<)��g��ǰF80���64���ؑ9b�a�hL��S}�r�#y?'oΰ
��oLi�i�*��|}pq�$d���KZ����@��Gt5Osi'»j���퀠W݊���:���c�E���t�i����9��ܠʉ�!*l���Qɗy���|D��6����� lEEH.Q]��4��Ԝ� Դ�|p��p��������5��}���#+�jx>��2#���ܖ ����(N���,�������ozD��"e�����h�b�B"��?��H%S"Y�s�����>ĺiu����Ql�rQR����lS�%9$�k��d9�g�8H~L{���F@c������������5a���O�������� ��%�+G� �]�r�R~o�X�*mVn����f?� @��<���m���Kt�֡�>ٸF�V�~3�|2N�HVח&��Y�P9��VC�7��rqs�q2�`�x�膃a�T��!L�^�l$-����<�#�Ƿ���
`�#��Z�Ix�Gh����c4Z����DV��������v}zM�C�R$��D&�tZ� �XG�D��c����j �I-�<~�n��d3��%+����;�q.4��_���?��I���4$��O�~����S0�0q��,
W��m��>�G�U���ߴ�u�h�1Pz�0+�
Q�uxb.v\dy6�@�	[�v(��7��0��1�k$�@�S�l�.P �a�{�Uy�Nj:�k9�XZ:^3�����CJ�4u'J�C�g���Ӧ`�����5��%@�MG�(Ϛ�gڪm�K�C.���(Y3�5��{t��0�b�=�x�MO�Ոl+�;t��n�H���4�(��� ;
�]�6Tl(�$����LTrCj#�#�5	ф?�a̯ߒ�j���B�s�����*�������0��Q������<�7��<�	�O%���_D����]fؿbcȹ�ے�Ռ<d���f���#�t�������b�����r���U�$K�W� �ٿ�JOٿ����/�����[t����(f�Lu"��*�l�@��Z��E�|THFy����7;���9�2���6�_�Ƌ��N�$����~�����G\«��i�ߟ�s!%���O	����r����N��|�ڿ�'�	rN$������B����"9�5��l�EضM�6�l�p��ݮl�N�#G��qێ��7n���;�hKE�4=���?D�s��Ǻm����aE���v��i�>Yt����M��	�S��i�*>��ؗ��>��	Pv��㪲��=�n{������ZZD���xr<������)����H��M�^�_-UV7W�1�	�̤/�!���:�Gԅ��^y�P�跰@�m.,8��r��qf��]ntox� �m++(L��#Dg��/�K.���%��٘������=�F����{#v��"ׅ��F���Z�_\��b�仭 a�R�Y�{ӞD<TK�_4	�"-�f�)�M�Q^��g��Jܓ�o�WL3�ޙ-f��tF7�uH���ކ����s��|��6�Įg|�_�qt�-��04���3�_6!܍�o�&��A��ca�
s�I��4�gj֑�����,X�Q�nQ�,����!���@<,Q`� ͦ�$�"��e�a/��v���b�������؇��}��=S3Nb	�Dtb���7�ŽjԠ�U�oVVKkU���r���c�`eq����NS" �3	f��iN=J�_��+;l�+�U^6��Z���1�^y���zӁ�--g��^�V�i�?y?�#/�&d�'����"ʫ��h�Hl{�!��I�"�z�B�ܦ�I���R�=�^
�\���T_�s��0�B�'/�j�wZ?E~�^
6_���^���)�9��V�yy#�����8�3�����BZ��������(/>��,8:���������T|z�/���?.��˴���+�_�Eď:�sPS�P��"	���g����k��BH�Z#4��
p\$�ϹP��H�_T�Z-Ls���-��v-砮<@MX�ҵ��: LVcP�XX!��� K�!q�[������mL^�6uB���又}t	�no�8���h�/&!��g'��>�$�>�[
�sH���ݖ�Hf�kM�CL�� 8j��i��ם�2�qp�)GT��İ�l���Dv��dY��Pj3Dh}i� ��K��0�@v����7:���� �4P	���H��@GYG5MWÎ�6{O�u���ƴ�����4#��E_��O����
ݠ����d����sȎa͡ ��(B%9��Ud`�YdP��U�F�_�����;��ع�\�ȶ٢2���hkL�lί�0�E��O�]�ap|��W���1=� >�E[Y�%� L��"A�M�<��T������
�u��:�J�8�}Z*�P P�Y�l�=勸����v����cpFD&tg���"w �kFP�q>V���V�!׳S���gk��ZpOp�ȖX���f�z�M�X.�s�:7�T����N�_^z"���,�<Y�NJ}����DOp�]��P:�M�rLy��`��,�&��D�m��D��ǘ{�m:�%mԆ͢����p�ŷ� �衬{�6
y�u
�0e�'��"1�����@`yhb��N`��u�q�'l�N�*Ķ,J���q��Fi�2���*)�1���Y�-A~l82�f�٤���e� ����8�z=цeJ#G>
�~��Qc`�6�ٳ���Ry�v��롬�����y�RJ����R��u �)�O�Q  ����6v��ȉ�Cvs���к��\Ư�5=���@��ॉA���)�1#�$})�e�Dt&�oiG��Y�o6�� �����;@����`��☈(r�Y_@3�r_�z�Y ���.�,�=unr���#� 5�I_�Ôln���������6	��4{�6�i] ����d���Y3�8�P�	g�Q9�J�/0M�g�Ν?$����B�dn|H5���I�����M �`�u�c4ر@���6|�l;�(�l�`X���5YUp܀��2�a9D��ᶃQ���g���N�&CZSnZ�Q��k6�gı�D�aj4d��00O����/(]��Dr��^��݁L}�3�߿���d�|��q*��ń98/&W��ڬ����X�8����2���O�q���|2-N��%S���߅������W޹����_����_����]o�J"!f�[�����j��r&�j53bBL�8!�D*�if�	ENd����L/'��r2��w����M#I�����a�]�~��eB��.q�x�'�a�׹��ݟ�}9��˓H��|��O8̽KW'N�{�_��7���0d�0�y �P��o�~�FA�:&w�0~��c��l���g��������h���������"�K���_@��WQ|�����2�?�׭��-�oR��_��������|�;����B(p_
��	܀{t��w/�����cwz�GS?��Hŗ�*�y9Wө4|<�n�q!�S��ߑL(1��˪ �ɖ���8<��]}��������o���K?��/��ͯ�?�����܏������{/�1��C?�p�������;�������}��U����������w�m��?�!%W\+UP�Xo�VKy�Q��\�T����y	w�R���ڥZ�^s����}���e�q�����
�F��~�9�߬�ji?wT�9=._�-��jk�޽���b��$a��ϕ7j�#?xx�t��n�����Ѷ\�\�W�R���}�ܗ?��7���9�u�k��=�����ڪ�������a�QT�9��H�rcW,z�l@	���~�H�����~-Y�(C݀��Fu\y���I�r��NN�mH�N�\/��lh�b�*�>�[��A��w���ުD�֋=�CH��ƽN�[��rX��V{`���������Nb���k�m{�b�-�{��6�)p�~ew+9p��W���o�KG�|^����TS
��T�j������[���{�\W����s��n��d�r6�#��)m,�ѱ+�nޫ=���:hr�������w����) Lv�J����
��:_�j뱜s�^떥e2�=�OY�]�r���W�Q���I�b.v$YD��D�Ԯ��dW�v��u�-z����=���u�D�V����5Z�I��o��[-�e]*��{?�oﻹ]��.�\?��'�ni��S�����;�R�=ڸ���te;��lm�ui�X��f���w썒�E��*/�8[1��F�R8n.�?9՚ֈ5)��5ե��i�Tn�Xnm`~����^�WO9*������N9��S���:S�v#P�4��.�'?(�W��m֦4
;Ц��8��
Z���{Wף8��G�Ѩ㝝1���N����m���+��06�`l0p���m�7�`�jr��HQns��\�_D��'	�*���������t���.���p��y�9�{��N2���	S���� n����q�� ���jk_���"����������T�M������4M��c�c��d�9'e��tb�;��r���:~ec�"ه�=7�TN���J2T�aQ���ǉXc��M���tT��S�.[Z���5&cJAV�T�ڼ1�������v��W����J��2*�Aˑ:l��!� ��M�k�,!Ai��/~��m[V�� m�c��ȎYV士$'�D�����{Cs2�@�vc��g����\�n6�_��S�a��]�o��t<��*vxY牨�S/+��{D�>0������L2�s��t�-?�90�:��i�~��.ĥ-ʉ���u�Z�F�=O0�v�u����1���/����L�')��(�����9�۞��n|@)M �6?�_�,��s�ܩ�P��4��O�҃j�������i���Ԏ/ ��G�������Oo�Z�f��%Z��;k����!=�̎;�O�Uy�X5l2t�X��=�WZ2ET;61h'�!��Ql�L�O����:şw	?�`��e�eĆ���m�&M�Z�fǇu�L%�H_%�?��%�&
m�*Cy� 2iF\GH��0��c���^f{��
S�6�<Qjֻ!�t�k�_�����m���o�eg����ߖ��h	�+�(}y�����^�"uo7��|r������o|�+��O�on:\e8}kkqt���ߗ�:z�����;��<�f&��K�{⇿:�w����^�(}~��_>rY�߾K��ա�?W��_C��s���?n��[��oK�������>Je�Ñʆ�m̗�ʶiF!�⬽&��5�݋�o�:�W�8�|���ݤzM,���i��b.�)�Y=�sAOQ�w���.=��J���S�Ή��)��U(P*Q,�5���	2w8T�K4�eu<�����j��P<���e˫�u��Z�����5g���k�p��a}�R,?s<7ZJI�lT�CoVU�P^*�ZI���6�Y�r�²�?1��؜	���1+���z�3ٔLk��_}�B���َx��!��2�-�tlK�Ց�v{�_5#����[�~(��
�Ȇl����VOrPsԙͺ(bz=����G ���l�I\�(B�iN�H�>
���7"�^y��7,y��+�S^�ez4y����4|*���P��
,˝��n��hF�f�>\�������O�q_ Wl�$���6:�G�ܫ8�'�"�
��6��0�k���|}L8K�c�q���S����CW��o��Q�U'�5���ۅp讅<(�a<��Ъ��m`O[�֗"s�u�>��ր�+�;K�:T'q���l��Gs���;���x4�2�+MS���*�\e�Z(�*�&���2�x=�l`�v*��!��nL�M��F���өn a\g%w^RԋPm�`[�G�jo�n���A�Sj�����b�[�p_Nf�j���]�m;L �DE�I�����H��;�'�h0#t� (���N.*�A��;i��z�OhfH���Dն3}9��FE�1ٸz�JG�6�,��	$��I?N����RrL�����	t���L�;�v*�O��y(�2��N׭��rDM�����Ԛ��Z���R�#ַ��v�r�����D�)�}&���jԴ�YtG>=T6��F�4�<5�@���@@�;����˜���C��<�e�t�<���+���M�5��
���Q�ЀPH��mPrص؁��z̮�ng1�H]����ls���#{�$*G�b��DX �{s0p-�h
Ӧ���t֥��.������]�u髻��|v֍o~+������k��-���x^MG��_���t4כG�(]@S���%�E���|��_����~S������?~>���Ww׼��.}}�����#�+.�����px=��>�@o9�����s�;蛚�[V��`q�C�Y*���<����]݇`���F��\%�݋�;�W��e蛛�9/F*����o_��^$�O����?�����~���m^��������,����Z�{���폣
�e����w�����1�&x����X̃F8�"�����Wm}�'��?�.�;���g�7>���	N��^,�7����?S|��]�&��x�h�'�?�������Oc���Bp��Y #���UvO��������������Z�2� ��?w�ǐ���r��v���b�� ��?w��I0��
���}w��҃��^A2�?md��o���v��`��L �6@�H�x����{�E!�����,�����`F r���[��������LP��xd�B�����?�t����3���9��E/�?	�_�U���,���?o�W�'�K����E����`@�(�����C����gPmT�ն�Rm+��aP��n�U���Q������[������E��  ������ ����?���(��Ch��rB��o���x�������?o�W��ы����oF(�����T�!i�������#\��x��<��.A���0������B��>�w�SG��.�?���w��-w������?���"��͂9	I�tl@��:�<����M���e��e�[�B����i���ͦ�զ:����~����U�����5	�;�4�*�����pƔtTKoU1��9'�xo�\-٠��{��4�	",����]�T�x�P������<��@�?������\���_m`�óE�����!�g*&m��f�=��^N�[[��~��7qu�	�������9Ԛ�d��EYUg3�g�H�@Gވ��)^�nWZ��.�����bsUr����p5V��=�&�:�|d�m���E!�?B��ߜ�k�w�W��S�T>(��/���@����_ ��� ����Ѐ�����.�� �����������񺺌������P9�>9�W�p�w���$t�L�{:��l����r�m�$��Mc�7����l�;l:�^��p��*���*���С�X2GI�{�V���J���%n��F�D�ݺE���#p+�%����r��)��B`�WZ������@�r�+\�)$}��;����J��Irr}k��bUT6�R�ݕ|��'5_�Ee-\��(�KnU��f�Mf=�v���g�Ǝ���X�!�Zٗ�(Y������P+nv	G��(*i�b7k;�mk��滋"�?�x`�������k��E�?6��<���?�@!��|��A��L�	��"�����y�?�<��+�?d����k������`�7��_���`�W��k������
�����?��Ka����E����
��g�����R,��?���D���`�?X�������������祰 ��y�"�?���!k��������B ��	��/`�����E�J�����G��7' �_Ld��O��8���	
�����_(X��	����w��AL����������/�?����8D� ��?w���!��!y�?������������������w������2�� �?����C�����_@�e���_ 7$7 ����_!���y�H���`�#��������	��������GYY�zm�f8�*]EL�����5���?I��T�Bۺ��ԝu��4�7�@7��s@*�hUe��5њ�mlT�Ȃ���P�A{�4T��k�l�и�E0$��E�N?j�T�;�1����T�\�;fd�ѥ^��I ��I o�i'l�>:t�>-�q���n�x<y5W���FXyT���\�"���2GF�L���R�=4$٭-��.<J"�s(���=T�g46v��Q��>�������?P2O ����_!��������
���8d�(����#�& �A�GP����|�(�'�������n(��␙�����P����/
��P远����x�(^�=��� ���[���q���#B ����!h��iߧl�f*�7��Iġ%1Ð
㑨�#6��>�zMyL�Ɔ���c}�?a��q������lp����r�h��������jl �*�J�~%*��x��q"�8	I�tl@���FH�+N�?X��+!�lt�mQo�n*����c�<j��t��/�=�o���\��:	��^o��t
IRNF� �mm�*ԡb���R�p'���U�IO��5K-e�B�zܻ�{7��^0!�����!��O��o�(B��/?��A��ܐ?�_�쫣���x�(���>��[Z��5W���p��xB�֘��ֈ����%����:�?����c���r)��fNLa>Au������d���S�Lx����X//nJ�K�i����h��%�������ۢ����I� �g���k�rן�G��@!����� �@����_`��\���E�$����V���V�5F�ۖcedlŝ2�X����75 ?��{Z@�p7�<	��=�xe�z��eY�H3�Ӎ���Q��2z�O4�qw<��񞢌����Rf:���uw)N��ڪ�M�<79�T�A���l6��7:���W���9���;��D�-��W�9.v�D@�w�=��������ӓ���L��g���I:��������iby�	�h{m�4���GM	!��?3�ϫ�vxE���	�9�/�"˨����X��Ɏ$_���^��,�qg͘��]������"�bq�D{)TA�t��ڨ����z�������?[��楞���.F�L�.�H�w��cHv�����{�!������O��(h~����Y8�EA��{���_$���3��*���/�� �G����_�������>���lDG	��N�<Iގ|#��+�K�4����ǯ���A��s}��
�>�:����!�W���5v�Q��l3�v��IP&��h�h��᭲)�}b�H�}����a�-j�>�@��[���x��g8��(�t���M^u���@���!���:�?ɼ��eq
����oS<*��'h2R*"���4	)N�8ɦi�є���I(A�GD𓨃�?��b��!�W�������z.CS�x7��m0?$�S��=�ɩ/%����r������+ߪ�����Z<�q��*��6{�T����14<�Q �_���__�����&y)��������h�������|�i�����(�����:�?�y��������W�����@��?"��O��?��$ ���n���!P)���������/P�����������+��_�����ʨ��G�}�w���W���r�g^�@�Q'���?^~��>T�����W����/���˞˲�����V'�My�k�AK�b�R�Ee�\��vQb�XJU��л(�y�F�'Y2�l��?F+f3q��)��Z��iyd��+����y0���E�M)��ԴC��6��"�Ȕ��"*�V@�=���u`���߇�|��q̽lQ��ou`'���G�W3 ��)��Z����hV$��I��H-~�(��蜥U��N��f��̾t��Ma��5ս�fY,����u쑣5!6����q@l�c�:{���Vj��=�~�o�]�x��RW��?�xu��)NTLj�~#>�����R�����{Q�虝��~��
%�Ƚrp�m�]a~�)�9�m}�����"�n��˪Ös����g�y7o.��^�Jf�/�Kc���]#��rG����2YW���c��8x{GT׼x܄��;�;C�$��٩��A�w+�E��h�7��!��_1�֐���_;����3�k����H���?�� �G�?M����"�g�_�����֡�Z�sܔ�s>�f��Xگ���˯��R]q������ٿ�uPjH�'�%�kLW!�)�]=��Ԧ�e�Qi�u�tu���������5��5l4��[.㣩�9��C*#5%���(���d�#>�TH>�w��"���z���d��4p�a�=r�x61Fsf϶���q;���.FCn�x�$0D�ăٌ19��7e���^�q�a}Z9�Yi�]W�"�bO�Z�]�{�e-��qƫ8E���z�^�S6D]Z����I�$`;��(��v�$��z;\n���0S̿�XOMex&��'�L��b��mCw��|p��М���ҙd�y�P8�q3ӳc����㼝+�@�KS�l<4�~���2-p�������z���^x��GG⿧� � ���_;����3�0�	5����H  ���!����7$���Z�������8v	G����,_:����������Oc}2G�!*ح��� `O�`�ɇk ��a�^�?-\��3m��6�������gk�Q�΁:Id����q�����yyl�0��E�dA��8�b�l��t�h�)����2ߔy�26��: ��=u ���iC0�S��e�#�%��q~)���u���������u ]Q;�B��J[`bE3S�
�k���d�	�3C�;<�,d]w9��ZZڂL�gg��{�]��b<m�"M�ՑgW��<�E���2��������_;����������?  ��������������Q���xP�IB���:���\��]�=���v�W������#�V�O�h0��S<�x
�S^H҈�H�I*���� �(���!$� �f8��n������Gį����z��JF>k
�E�b~O�b�X�h�<.ۭ$�8��&���9��\؞�lLoqi2׸镼�a�a�p�m�93�e�xC�Tg�<��<?�=2!�Hl��ù��\<Y%�9�M����:<�a�guT���/�зJ����W����Qu���7��j�~7�u����+�_?�L����ܲ�Xl�覉�����Q���&���Y�(����s��~p,�K��5\r����lyh��x�c�a�Yr"Nm}��&)�9�e:ٜTq�ߚ�~�"7ͤ�)C?���y�0���R��?�ߊ���?
��v���/��_��U���_���_�������ĀP��'��!��|~��������?��)y$���`l�#/e��7���ů����-�kI���&\<������6]o�ظQ��:.�-K��&�p����nG3]+��GB�f#w
zdDNf�ٹx��mJ�u�u3vC_h��Va�y����Fٷw�6����ɷ��kK�)]�.�LiK�?�8M��=2�f��K=�V�����H�U��<f�{ԠWX�g��"�TlY׸S�m��9=�D8�Ԍ��}�<�թ{���� 4���7ę�;�"�B7�u"��}#D2�6ژi$�-�h���m�����u��� ��U��?�x�1(�������4� ��Ͼ���C"����5���j�'	��"�?w������_i�����
�_a�+���������D ��`�KM����:�?I�p�W��V�ԉZ����4��#���������?���������k�u���Ձ^�a�K���������?H��/������-�?��A?�����H@����������������P�'���X���8�+�������A��C�?��C��������"M�GA�2A�8��\���A�,-$γ|Ba|P$�BBs	�A��>�:��G�(��D¯�������o<f���.�1��E�ԲJzjm��L:��������
ǛL��=7���a���F�`�%�6�U��pR�ڽ��<dqѣ�����s�L�#��h'��vw=�Z�a��[���x��'�������G ����H��� ���:�?I<���H@����WKP�������$@���A���U��g���"��I,W�&8��W�	<S���8��'���q>�"�ᨐ��$�ㄠ� �#�O�����g�?����6Ƴ�~�Η^�m���M�M�����5=�?)��ixT��?;I�i6�l�(a��RE���G%dw��1�9������$bO��)Z��nЙ�w���M��<�p!9���Z�n�����J���������k
�����?��A�I�A���G2�������Bŀ���W�����	U�?,��������x����AB�6CT�?���ϼ����#�N����A������� �`��������a����vCT�����B������G$�K�_I�ϣ�����?"��ܫ����tO�{,'{1eIð��>���o���ů�����om��?�M���{�g���׼�P&!y��e2Jyif�poo��>�Ȁi�.ޥ:��o�r����꒞��|Z�z��ؔ�M�]�����vX�2����c���h�哿W�;!dSK�n��l�z.���c�>��6~p����OE���څ�J��㼳`�u�ʓ�d�0'�N�(�j�:��q&��Ŗ��Ф%i�_��Æ^b�"���3B>4�+kb��?ܨE�����t�!��a9x�oǗ��׎�j��̃�/�DB���D!�����'������`����_U�����~;����v�W��_5�������GF�?��W�O��o�������:��C�q���z���,WK��+����Lqq��SS͓r����\yaMCu����C0RN����?����c3IŢU��o��	ɟTW�/�]E��E9���4K�?`�!����ܯ1]���Xw���R�F��F�5�I��񞫓��k����װ�\
o����2��\���?�e9�G�>1��,��c7}Q�uQR�q�lB]��9̻G��&�h����9nG����h�-/��h��x0�1&�s��l�ր�3�;�O+g5+���J]S�U���[���۽ղ�h>YuǔĔWĹ(�r�����^��!��j�N�%�9�Ei���� ������r�5gd��� 8�b��Ǻ�:Y�3�T<Y�e�0l��l���惋����t�7���$���+��Q������WV���\��^�w`㡩�|v�i�;Ɩ�p������?"���"9�|���G�����A�)���G��H����iHpQ�q��D��LH��B��	�!E|Q,�\DRa�S1�@�x�Î�wS�8��?~��������i&��f�i�X��qwN��(4�c����x�?���;���ï��I�	���s��mb0�<<3�+���t�~����o��n�168���E9ǁn�T*U�J�R1��Ud���-�c\f���^m�~̝n�N�������"_��������b�Ñ���l�P؃�V�����)3��81���h_թ�����jy	��:����^�}}����%����������?����/:��6���W^��_����<���m׺�A����iPt"�i��/���'�VM1�OOϕ\�٦���j��|���2h%�mL����q���|K#�IGS*���l�b�l�L�Ҭ�|켝��~�}��|M�[i}:����D�w�[��V-/c�Ϭ���T^���иb�$��������������������?k���?k�ʋ��`�w��SX�OQ�������g���A�٫�(sG��W�TM�]}����?K��������m;���g� D�ß�	ڳ� ����}ԕ��BK5�� ��(_��l�䠔x{蘙�o���H^�Z�H��n�|�aR?�5�;�j{��MI�4��K5�m!��@{U�r5�>���:�n8��|p�L"����ݧ�������������<�������W�0�L��~b0h�����r�����XX��(2�om5>73���Ȟ�G���@x|<<*���e��s}�x�ӕH���p�R:�W굏���&�T��7���˗����}�W�F����~�����ÒV>g�	�1��i%�/���<��~r�}ښ�ʍT�������k�������O�H_����/d�a���e�����W�b���6:�^>�o�8NJ�N���&m��B�G^E^�N��9v�)̰Y��2������4�ʐ���$ԃ���+ -ڴTfqKÎ����fhho�O̠�AFԠ��cކ���F)�O1B��Gx��G�#:b�@�T�Ռ"	�m��C����1S�,v#-a?ڤ�tsB��EP���a��� ��G�R��0����8�w������h`?
{�<�R�ʼ��s�w�;��� �G�X�3�lb3�3�cfО��19뚢9 "A��D3��t-	O�Ӯ��*N��!.�t�L4P��]���t��:읐FA���&�5�,:��!��X�vրٳ)�mk�Tu&&��BW�����8B޴�WW���I�C.���
��#6���|��8��i�x��*��\�D3G�eFAlKS�`�`�J�W�"���;���ha����,�����௯��Mp��u�N ��46{ԅ����Twa�}�qdp�>h�-�H B��w�b�������v@���~�4�6��OI���EC	�8�M�v.X*z�k�]�z���=�6@�B{Pg!J=j�����)OO��igNl��rQ
)���ȴ�T%ΐ��b1�J�}u�裺>� 9�Q_�7�D7���]0���Ԩh�D�S1]É�<��b���Mgr�X�� `�WB�7�|�_���R�*�"o:�}S����E��ه^Q59��8>��o�7�!l� پnD���	c�������R��'0#=�JxR���Na��[����ތ�8W��h��w���8�뚍`�s�!GĴIJ~�F�I�0�n-�pu}�8M��PC����	�s�'K�����J���;���jLU�K�2�p�H���MВM������\0+&�c���n���.����T2�Mg`�L�����>I��,���ב� l�9-��,XK��p:f�����d�7J��>h�T<[�Rcdƥf�����n�ܮW�*����Qm'�%����;���Z?5J b��jlZN`�- ���hs�:.{Hb
y=߳Xd@`1V�YN_K|)��!�])��6���6��s���%�[ɂJ�T�e�$ݦ����mVHn�X��T<`��tZ��f�K�<eg���O�U��S_sj\��;br����Dq���)0Шe֙X4n�J�3�ɖ��T\¾���x�ٮ����{�F�]:<;l��>�wT�s�W�w��F�Zm�:��d����6�ߩw�j��fu9eY������v�|m0�Yv���Z�cP���Q�U��H�|YZ�Zo�D/|KB�gdbZ`����U$	s�$�:Äm)�X:n����9�pi�	<�z�=�����dW�\�jaI0}G`@�r +؉�����<���Ň��~q�%�������f��̾Wo�-�x^��_�7*��|�j�|�����֨���Fw�5��b"��]H�Z	�5������[�j�|��w�<\��[�
l���[�Y9����N��l������f��F����YФw��A*(@�J�T@o���7���f6����tKݚ�[-uK�R��F�2���_i�T��e9&��#����^1���}PI����Ob�8Y��`U�����"ʩ���4>I�d�I�6q���f�����f�s���r��b��_q�*3C���(��y�Z��$�����e�z.�ݭ�<��9^@Ɯq�EU-����+��&`��:N8o�1ܵ�!���,�����9q̞��jܹZ)bk��/�Me��������I��!`�-tBŤFى/8돰+A��wƗ��֧j�ӎ���[��di8�	���L��N�N�e��;!V��0�pw�|ؽ
U�C`X�}�W��Z>��� ?��Y�������)�<�O.����Z�����?k���������?k�������<��GR���v�T�Ww ��=kw���s����a�R͉�������},��SH��_��t6��������ӔWK�4#ѣ���kWi��f�a�eZ�����P]����`�\�A�*s��Ab�P�O��"(�;�ty`Rl�O�g�vR\���VXA��iM���o�����эﰆ�u�'�J��_�Q�%��J�>!���P��v�[3UdG�ͭa�=]G�reD�\��k�#J��v�xXld^�X5�spYsX��;�O���{�j���'�'1�[~�F�xzIPR�Nb_7�Ӆ���v`�ٰ�N��3j���V��1�? �X��.���:�Χ2k������$�@D���5����>%``��]S���@�cu�/����Xk`UE�D�sq����d�x��ɬ��')A�_(����ذ���$�#�0eh�h�����e��?bCO�|2���h/�k�E�AD�O�l���������^*�Hu���]�)^�z�4ywF�́7x��F��(�:PM�C����0���� jb�t;	BM�Ʃ�u$Ң���J���-�-h;�����I��~l"���P�,)���ta�x?��_;l��M1�O~�M�A���Ć��N�+�P�;�y�����zM��fB8��Ѭ����\�̦
�'!	����7b�&��D�>4�7P�;;$�У8~�O2�9-���^Q~|�I�ʐ)b��$Vo�#0�x;�Fy�B~�L�S9�di�&�{�k�pu=0�u,����ۍ���ʛ���T~�v��yN����JR!���0���
5�R���/<� .~�x{@��`�L�wB�&3h�O�G���rbㅋ����!56����<�2�@���E�!�da@�*Y��5�D��QR\�,A�2��޿'��.��$��MmO���iD��6Q�h�D��}':��͇��^���;���%Pw`��b"�
�}ͽ�Qr�+�%!(��&]�#-��w3�uD�%$�<
"B��4j��9iF���o 3n�^=�k�I��s|���F��^��ҿ��X1�u�M&�� s�O$f=;�}Y`o���떟��P*����d�|��T
[��Vk���loK�Φ3,���T�T�Qhj�@�{���4�����qx�mm��/#s%:ST�X頤@e1�gr��4o�2~�fk.s����У[��+�v�y�m�tw�h��c_3����"��b�%��b�'1w�?���8u�o����Y����$�{��n̐��X��TB��0dAS�ә���<�~TL`�	,G��a�얩����|i9i�pm�Z��BX���S���F^n[�|�MY���.�)���y��&�j;�e��T67��%�^��<I�Q�������j:�L�i
ؔ��sr]n-+��O�F�2�O���O:�J�׿��e��������I������o����?M�9���C ���'�2?�8��y0��T�	1eC���ݔ(HPM3�CVINe�L`��G̴����wD�m���	��w��v��[?��~d�N-�I$"�],��ս��:c�[�v"�^̗���ǐ�)�Ę��Y�ߛ�C6�i�;�9W�{���Y<?"�����-(����F����C����;��ѕs���z�C�!�O,����ݤ�,K�?d�G��,�x�G&����$���?��GԜO��r�>�D��@x���|O"v��1�^��g��\wX����4�G_���p:lr���*����<���?��T����/��o1^)�(w����^�?�.�S�t���g3ٵ���8�1!ի.�B��Q~�����3���2]z��6O���Y� C��V!<�]��ɘZ�9<^�������i���C�K��.��j���΂���b�P���"��|SA�v�B� *ܖp:z�����uaá���&�\��M�Kz�{��\�.� Q\Я_�4�ܑ���	��a� ����q�Q���x7�	V$��P}�f�:Ѹh:��TdŜ���x#�A�3g!3�T����sd�t��7J��5lǈˣx�G^E�C'��{h��J��3{"����q�W]A���x:�'9�e��uz��0k�ȯD���D1N��9L�Q�78� <�$}�������'�q�ۄ�w#rh�*�.ܩq�H�@�O:��z��W� ��fy�m�j�x�GMFV�~'!��	PEr�;s�֛���Z��Gp-͙��K=߄�pkނ튢��^$m Վʵvd6��ԋ�N�/?<��B�¯��2���t�ehZx<�a__�f�Ƽܴ<�c?PA��A�	�-Ӷq� >hc�mu��A}`FW���gOƩ5��v�3�˫���i�������(��	A�＝9+-�G���oũU��fc�3 K��g�'"�xX$��O�>6l*��&״�',��̶3��qVa)���_��B!�.�EWA�D�PJ��}]�m%��G�>&GmS7��)���*�'d��"�.���l;|I�6?��n�:��]M%�#��ʕ<F<���������PJzؖ��P| i;��}chg�e��\����/�ph\28�.�s FhE�W�H����+m�u `��i|+7z%�yI����J=��k;v[�:@dA+���~{X=\�D�[�@���Ҩ�Rg(���T��z�oo��r���0��zc�Ń�GJ�c"O	X8��z@��e�<50*M ^Hm�lF�3��Rir )r�rR�\���޵�8��������3�3�{n[�KS�]�dfb;�ăFߒ8��8q�Z9��8q�{�d4�y@H�0�-h^о�������V ļ x@+� �vn������ꎳ��Z�:>�����s�����̃{���k�/�<�-7,^��mu��J��ց��¿��C~ d�_L���ѣ�d}�S4���"�>S�	Sl'�XI��%v��%���`I���C92=��t�d1پ���|�l}�}_��G��S'�Sf`ˎ���[�s7�`�C|���<�g����z�����5�����]v����7��$� ������p0������~���ᝃ��O�ţWO�K�������T��!�Qj����(E��b(���cFը���SR#�8Z��8����wo���h�+७~� ���2��_�d�zz@gG����[��ᭃ['�9:w��zz��X�}Ͻ��on�/�\��}��7��n�/o
���t��H�U���۫�W�v�[~����G"]x�K���|��h$��;8:|�F��Ϩ?�����7M��7.�����������_��!�|3�k���r��G�xɛu]|�n���#"�H]Wa��I���`d�A(��	��r�i��x���(�P�Z����TBo��?��������?��O�N�S�����.�C�C��xik`��7�o�q^���u������w^?����b>��}���?�_Z�@g�C�4�r�ei��N�+s�Z��B#+I%t|�*8G���7ۭLV�9��̽���:yc��Ƃ���U�і;7E��|�5��D���-�TP~ίH�1�Js[��ؒq�UUݲٲLޔ1!N�9�\&׭(�UTĜ���[x��UJ�^�C�j�)�*N�^lK�����9;٬u���J1�vb΢B��2��k�t��UJ�S����9ǉ�:�R���ϯk;�SI����IF�Ѳ��̓��"D����0$�S�ө���p:<���Q���0��GRS(p=kh�#:�Iʥ\"Ԯ��<�&y��L�x�@��*5�|Nz�xG������HW y��,*+���vx&<�{��2��l�Ց�'���@G�X��j��I�iv1b"��,]�ۍf���N����C�h�`g�V�*�FLE�q�T���!3] !���ú�U���`�x��
8�NJ��(G��(=��%3�)��+<�b�8̇/Hi{�����כ4�$��4��E)4�����[&�.߶�3I���/I�9Z]'��Q�	n�P�+7I(��0����Wv��p��~�T��	���hj��H�=�+b����R٬�J-|DpMP�)I&a�ۥ"i�
����S1��7M\$�d��pQ)O
C���U���'�R&-�Xx=��^|G��6apW��tUuL2C�A.�vR�~���5A�d0#DM�	LU�gS=��XAf�aJ& ���Rѱ�:��n���	���K�HM�z��<�"�)9�wc]���#R�8�E1�Uas�b9�K�}Q�g��b>A����H��%�yf'�1;��� 9�i�B����c��Y���bvIi^�O���=71=�+�k��ٞ뙞��pO <��O�p-q=�����l̳�؆sq29�L4�"Rdd�ՒR�Z3k�T)���::D�r�6� 6K��
*V�9V�ʖ��9]��������ϓ��ڥ!��0XT��&�rZX"�ҭ��hd] �HS�;�5?i:1���|�"t����d�L�sbv�dP����Qo�]N�􄳤D��x&U4�B��hYP���h7lg%:��l㰅7��7��w]�7�������/y��J�mv�O<��������C���Z�Xi���ٮ��Π_�^v}˃���^��f«#=n��/l���ky����w.���7��]A�y����V�k�'���J>��>�������l�
��R*K�]*��'6_E'eh2Y�4�x2W&���W��m�c�_�|=��5'�$�wp��/�\G5���\3��j�f.��.��u9��\��3�n+�I��B+��������a��i9b��	��#�9&X"�zY=֒Ed��$U�:����B���8[5SM���NM׆��3�V1zm���N,i�B/Y�"Q�:�d����/̲ZY3��6��������`�#�DXd�B�3d�a���;&C��.4�!�"ɑ��]�θJ,�m�h�Ҟ�)���4��1<m�fY����xQ��N����^&�v9�*�kay�i�"�k�e������71KU'v�$��XXD+��پH�楝���rm#��J2,��,��i>���q37?c�{O��DFX���i���ŵ@�:Rsm��W1X�S���UfR��I\{&Y]�LX�q�2�����������,4~���.���v�d����L8�v!��ȼU�R,;���Mg�J|���b��m;�K�p�]2�BO/�cmL.���N�S�׹��B���&�j��M�+}I��9&\�E�Y
e~)�Y���Բ��Vv�.m�:S�r�Xb:1��8D�����Ӊ�P���O�gLu�=`N����SZ9���բ�L��J���yr�L�!8�_��4�S�cp
�'�6�0���=sF|�j"�$�����x7���<�&��K���x�dvbHDiґ{v�$�"B1�zS��gT�S�vkH�N�^�il�-p�!1�,�	���ژ�|�1Q]wlmLr��_���^nP�I;"�Z�텆���� ���R��|n�xvH7JhtR�����CT���)�3�4"V��-6�kOL�7�E��Ak�r�A!�ҏ��o�UGrCۑ��$���PKG�7 m�)��m��|�A,�˵����]U�r��f�I`��H7r=L�,�U��O+�X���!�#yW�0�Y3�Z�JT>�Y��δѥ�]�+��\x��K_�^ޖn��Ѝn��>��|�6���������\fņ�	��Fsu{8zh�{�𢷈fS�|y��zz� �{��!��Ç6u�^�^���n�'3;o�WY���e֗sH7���lҥ�R���Mp/���mЖ�u��x��(ss�,�SG�j��"��x�xt����Mu�[5�f1�C���-Cz�/��S9 /,��	�|�o�ׇO�ؕ�?l����^�����g�k��&��U�q��t���|�E����;�G� �G�=z��g�ݲM��A�҇G�{1��9R�2�ҭ�n�mw��-�����1:]z��GG^$;�"-���*7������#/���V�x�s�ql�t�=���c���P��M�����C�7��r��g�ܻ��TԱ}ӹ�c���Q��Mg���󦣎�Ǻ�����^�����m�M��U<���/l���0Bb�hA�A�]�#X���۽0��e�FqM�S�~�7��}�^�Q�_��%�G�_�% $����N����>H�E�]p�eU*��WP�XR���qx��I��f;�����Ucb�׵q�Zc9�����bI�����ul:� ��La*ѳEP9�����'#]g������M��E6�K�qI�w;=y���q"��v�`�^�T/X�w��~�~��Y����]�7�o`N��� ���E������;����L��� 
�+9�$����l����L�k�)�]#�j�.�y��K�eM��k�\J��q�Ւ,M�v(�\O,��1�%C�"�a�n��wVlfr��1K��7�Y���Xɠ:�jt�+�gi.��zGg�fWd���37��S�\��oG��9�6����b����pws0��ܰ���u�O�����A��Ϣ���y�j���������c/�?���|³��˔	~�e��a������& ��]`/��D��?��.��_��9��������������{����� ���?���9��������-F��D�������s��	�v�}�Mݎ5�W�^Oߓ ٟs��/\�O�g���Aؾ l_��I����c�.�B������N���B�# �"���o�������#��	����lv����a�,��?v� y����@�w�{������I,�����od�% >#���o�����g�$��]`O��k�
`����<g�?��w� �R�m)ȶt�lK~�ܧ���������W���"���o������aO�?X ������}C0������/�B��D��|�����φ��@����Ϸ���� g���d�k'���At�%��!�z�A�:�5�z#�u��ꈆZ�Q�Tw��0�&�o�ի���>��8������y��/1���\��\m��0�I��gz)��T5�T�h�&pFdW�_�nd$�%+�b���0\5�iC�m �z=���0�S�L��kbI�1~D 6�ڑ����h#�6fB*�Pm��%���~y���������~���L�����������?�y��\7����b�?����������8�ˢ�p���C�B�郒#�Uɰ�xk��J~����b;S�2J�S��܏u:HY��Hx\�'V$��Ǥ��h�~�Q�'U&��f�x��o%K�ZG��N�Cuʱ��wU����>�O����i���C��^��
�����_��_��_��_��O��|�	4�����g�_$�������/s��2�1�zC������<i|��_������%rL��Ƒ^�͜ҁL��`�m�a��ٻ��D�n{����1��/�o/gxE���Ƥw:��tzw��ΚO�1�̚�j��T��t�@�B�;�N�i�� �?i��aI�5�8(�|P�J)M�si�(I�1��v�Fvk/�$ᐋ�9mwm�h�����U���nq�뭬R��:y�r]ϸݦx��FUs��S�B>�4׫]�{E}҂�[��_Dߎ�}�m�+�,�A��Z�Q�4�u�|Uuf��z>;��n�0�T�C��Hh)�ix\�*#5o��q$g�NYU�TJ�|�^^��κ����V����Q�V`ҨU;"�����5>���9����r���	���������&�����h�g����$�� N�����l�#'A�`�#����0��P�/����_��c��9�����$�?�����/&`���@���w�ߋ���/@�����/�����Ür��k�?��q���0�0����?\��?���� ��.H�� ��g���O �O(p����������� ���� ��������g��&���������
��8P(�_7�� _������?�����*C
�?���������&��PRp����?�4�?� �?@��� ����w��@�aB��/��PR��m�G�P�W��πm���������<�x��W*���W�?����Q�fjo�6�~݉{�����5���?����=�sV�e��^�T���z��[�|H�U�p���u�ӆlUPP�M�>�$��m��î��uôLY�a#3��?J;S��O�lP=�81om�n0W,���{u-�75 Ե�j@:��w.}�X�����.c��J6�LCS\ש�V�liZM���9Њ��&���1�^����LP�jσ�4O��Œ�����������<�� �XP���搅����D�?�`�'俰�$����A��0�������?B�G����_!��C
��_[�����I��!������?B�G���uA��c8��]
���f�]����������9� ��y���IQ$� )2
'���@�"�3�,-+���$:�� �%1Td�����������A�s����<x�����E��0F/�߬���ښmj��ٵy�����FM3�]�\7�Ic�;�ײ���L�M��c����n:wZ�hQG�R�v��qu�T:m�l�q�KA�C�.���\����rI��ʧI�!���x�gli~���lv4��dP+��E;U���6=w���~��E}�		�?��,����}	�?���@�C���P8��~�_X���� �����_����~9�Ϋ~۬k�	MU�暳�:ͬ�h�,s�/�O��'a���l�$��ܯ�eYϙfc PIv�}aHs}ɯ������{��K�a�2��_KL��^n��ʗi4<�y�ߏ������� ���@����
v��=@D��
�A��A�����+r�4`1 A�	�� ���W����4H���Ў�l��2oK��bݿ��{��+���� �^
^��q�GKC̶�%}&%�z��N���#?XL�a_q��|R�E��cY�N���z�ת�/:������y\r�-m9׵��{�G]u��Լ�>�<��Z�|�i�WS��`j��W�r[�/�zT42:{��˱�Hd�\g�_�K��G�m�,��`�+�S��7w4��Wl���M���`&|/�GV�����E��� �e2�7hө�B'1]���t=묧�����D�h�[q��lR�.�E(Ys*���h����o�Ʊ;�F|��F
��	���� ����翜�Hp��$�F���i������Ӌ`���������DQ��0����/���_@�}��/ 1��P�e��"�e�'��x�H��0�}1HF2}�Jp��X�2��FV8(��D�������������_�&��	���j�v�:*�(\6JG����J�
�=�zP�=����l���ge��~$��̣�꿰�����;y������E��?����pW�+�,�?��ɿv�`8�K�|�'GJ��<̋��<K�b�)�$_��}�A!0�����Q���X�+�_E�#�6��V{�/}�2Ɠݨﷷh��G_lV4a�c-|��q��ie�g��״2���?�@�WA����d/R�k��h�G���P��_P��u��%�'�[��;>���4��0�����.f�+����ϱW����A��c�;�����������C�~����q����t��$�?K�����p��m��q(�������]����	��uLї�K���p���_�� ��m�wї�K���p�����1� ��_o�1��.����������!����ܹ����%��V�~k*�^)[֕Z(�s/�*o�9s�l�iN鷰�i���w6z��]3N�f7\�������d�3��޲bG�����2�'j4�h����1�����S������
oCT��m^BT�k��z��ρQv����gr`��f0��"���9��vy����^��q|ʲ=~�f��zER�eđV���d�����4��r��c!�{�Q�6�s�L-��,�e���V�tj��OM�ժs�2���O�<Q�"'��t^���_�k�KS��,se��Sī~�>�:2)�z�D}	��nO�r�� �&�PoX��([n�Ԉklf�{�mWԸ.��/\k�95G�E4M����a�s��Պ��n^^z�L!#�3��K�\�5=qW�^O'Aetn4��n��e�	":�^�Q͵�_쵎�bװ��gPnd���[��aD�G����,^�@A �����{o|��������O�M�O	��B�w�/@�/,x���W������[�S:Mʚy����X,ݻ������̞:|��2L�4>�(�g�c����s��:S��z�ļ6����b�E�z;�>6z�~y��5����[��^ƫ������6E�.&;CA}�S�����WiK�̽�8j.c.�ݞ��4�3�������)5���Zm�\�Ҳ�E#�PU4��f�-��q�Wd�+Y�=iw�1o��8o�{=�i��I=�k�f9\�m-������\U�������]�zC���n���fi
��4yc�MV�0�P�����h�غP�������z**�c�6<�ru>m�"����B^FgE(��z\�*�v�/�+}R���+4��ʩ�&���H�a�"��԰o�ڈ��t^���~m׏���<���_, @�=5��b ��k�?"�_x������,����� | ����������n�z�_�v�o�=��h�3#:Θ^v������-���oc}��&*�5�o2 �S3���3 �ہ0?���.R��6㗞6�P/A��4:�����R}�5�Y3�ͤ�����P�6ʠ�.&��MY{XWg[��,��z�w��Diw�I��W|?@�>���5*��ӈR<�9��-6]�R��	��%�����u��h����joT1dV�y+ռJ^]��2;	\V�a�[�)���ҩ-��0[��L��^k��	UP��"}u�ŕ�l������~	�1 �������0��� ��?��8���8���-����y��d@�� �o��l��� ��_[����ܛ��S�/��X@�3�E�t(�~D���r$+a�(<˅#�����bd	)>#!� �$��q�������ǃ_9��������YY�-|���>�e��c��òZ	�s����������t�[��H�J�>�җ����_x'�#���2�~�5g�>���f�k�!��\���f�֣�U��Ӎ����	�?��,���}	�?���@�C���@ ��~�_X���� �����_���g�R����Һ�PY��zmޞ�;��;�L�����X�g��Yw�]:�2�*���njMf�}ō�S�r�	�����ֶ�������(9�궽�+��&�0�����l�����?
2�����
v��@B�꿊�A��A�����+v�4` B�]�������|���ZO���o�O�o��>�w�;t��A�b����j����M�]�]Ekc�I��cH�H�.iz�E�ʥ�a�lE�[%~L���T��`f��I��6�ٌ"�I�A#�č�8W��L�F\�8�Y3��wZ=䤶�ɩ{m7�������ӭӯ�׫j��]�;-6���S�M�[,�b�Z+�q;t�C_��2s�v�P;�bK�)g�⺭��Fz_,����VM:��V�����á��䉕��O����8���J�l.�u�Y��c�Jm,f/�Yi���&NjC��ܢ�Aں����
����A�?�Ƃ�_�a�+��q��;���?8�`�/<�8��<��]I�?����2�^��殤�t�+�_� ���W��
�_���]���1���/�����$�?�2��/��F�"����?�,��?��!������>O���R��k�?��q���0�(�����������_~k��@��c���<�?���?@������3���� ��Y�A�?���,����4�=������?��!���B��pw��_1��c��}��eZ��	Æ|@#!$��J�,�!��	�2�Xv"+!/�Q��>$��G����@�}>~���q��/�V�	��t�c)a����+N�O�m�?���o\!|����{W�ݦ����S�8�NҎ%@h�{Z�}��g���@Hd!�M�O [���ɋ%u���sDQ�*���ս�:�f�	�u�{�L�Y)�Iﮜ[�����B���M���I�9���37�L�+��}:_�|�{v�L͋���J�0�S��2�A�����x
�D���3��x��a���|�=��=
��m�I���x��iR��/�������7��<��c�� t(�*yy�*$s���)��"IM�e��r>��d�ɑ95%��ٔ�erP"��Q�� އN�������~e��W�ot��M��'��q>�w�r}�R-�5S��[��R�|����z�.�vəgU�<Z��~
�5��κU�����b�rS��h%���ݽMmmб'F���<\ވ��OI����J�0��������?�o�?U:D��L������!��&���S1�����/�,�Ǧ�c�?>�?����9��C�b������O����?�����G��c�?:����b�?����C�@���=��N��������������������{����p:��ѵ��Ǣ���������P6v�?>�� tR��?SxG:���PR���^��C������ފ�-��˪�Zmz+ӷz���������3��鏇�u�ٽ'^��[�r�=F��H�ިkw�۾��+]���\����3��"�ϳ�s��U���S�}��3��Ì�4G�--H�[2;�F�.8�{O������~���7!�:���е�r|ۯX�Ol�����]İӮL�*���{�����rz=��&,X�Mf�Q��)��,U��eu��[�2���'��P������sG����8�����1j_���t��}n���B'`�m}�ح��Q������I�zO�7���A��?>%��t
����h&��A��O��O��O��O���G���>~����(��o��$�?���F���,��߱�8:�?��?�:����������i�k%ɕ��MV����~���P#��,��'u~0���{�:�Z��5&Rɘ#���ª8e��=�W�{:W"�y�����έJ=�&�`��R~=����d"�pθ��J4�*X1�S�	tcB��{3��ܨ�d�1���^�l�*��M�4r�F���c?� 6���P�c�����a��iv���;}�%+,W�r�צJ�U�WX�e�q����i��&İӻ��fm6d�N_�U�Z������qv���F7[q�J��3º���i����,S"�_��qߖ�[\�N�c՜�NY��;��_�۳:_e+���^��py���f~u~��w�\�M�䋙�N_�ˌ(zu�zx-�u<Kjl]��6�8�v���N� ����a>91���B%����K^Ij���f�y�z�XEKX�Bů�^����-���<��.�F������N���������x:�o׎k�0���@���{�����'������S�E�����)E&3��Υ%&�&���I�H9)+�9YNeRb&+�)I&SrFN��)��d����S��}�����a�W��������J�V��ld�rrK�>�Z���yj闧��͝&�����v.�t�%ә,%a���P����G�1�����f�j/eӚ��/9v��9��
�Z�l���H����J�gvVQ)�����Na����<y�w�x���t
����N���?�F'��a�	��1~C:�����ѯ���F[�yU�|i���%�qGͰ�|�?�قlN�㩜�B��6��PKe��ZI=+6�N�:�h\���}rB�~W�y~5fșFv4'�XZ���{�6|��z��p�g|Gn�KV�dO�c��t�?��D'0��bB������Na�W���x���������_q�'�����m�c�I���3�/����C�k����Z�q�Kc�ϊЛ�dk�%��j�l��2=���{V٬�/��@����� ��?��ضg��@��\��k�x��{ ��R��N��&�k����[&=#gc[%Z��$W��+��9�v�/��Z�3�e�7���gӍkQ*���Ϗ��ֶ���kΧ�X�	m��c����9����x@�_��:���ӄ"��O���a�@��rR�Z�QZ�����]�r�sB��r��f��tL���y-<��ݞԹs�hr������j�'��0��2[�|ETɪ�-�ɜ�]����hT-s�>R��IX��n�,�i����擰k5{k>�awn���н�s���Tr�����w*{��9�O�Ź�j��&�л�O�2��!����ֵ�*\]ً`tp�:0�%A| >�n�psQ�eh:�@��Uڗ�]��^�	�C/~!ngM[�v`j8g����:68��k� s�5��Pr�0-:��J[��$ ���1���w�}�^n� @����y	�� �W��9�uPz�!h��$hX>P-`�1�� �P��Sm��\?qÔ-�5�Ɖd����}�,���~����W��Ux������xo�}7�}�~�����q- MQ2 J�HO�.�.R�m� �u�n�����p���@� �Q�!Lw��#��E\���@��]�5�ƐC�'xm�j$�@�mq�ĉ�^��C����e;:����@C��D������<݆�Лڏ/���Y�GD��__	:=�ŇGmf��l|n�!_���*|̍^	�cZ��ub�y`�K�Y��ޏ[�=�������r�žKg��ؼ��o	tJ�og�e�Ot�Ɩ䢼�|ԶK�����5*����5�-�NH��2�:,hKh��&�[h���U�Bi�<�c�Pʳp��֫l�8�Kgq��vn�qӹ�CQ�� �*��[.%�go�$�~!����e���/ȴ�|'hU�
��ܲa%�DDM�.e�Z)���<l􉆱��'>�@⹖�5C�gx8�w�,|����[��^P�Y�֏z�kizs	����H>}������J�T�
|���/��5T�ý�J���ڞ����|���Ď
6,��؈5*C�0�傹�z�A�Ȇ� -BX�y���!�,w� �	8��E�+C��.�e��q_!DGL{"jC������˖a�f�N����8v�%��K�ݸ�/A�!�Qe��l��o���
�o�P�HL�O��x�{?]�ڠ�#�xl�,�{�E���(���b���y�����^q����X�kI�n(	w����+�?�P����0��
�94���.���UbO��@��e���r�
�K�-�W����0����.����^�#ɉ��*����܅�r�%�@�A�.��~B�7�ϑ���	�+>��(���f*��Hb��w� 6�����@?��
�ܢ�ub����l���ƫ��,��ө,��!�8�.�'�A`�e�!{b�}.jhP���6��!��DF/?����92�����m���c�e�m�Y��Е�{�E2��������"{*K|��S8_���P�f���S�_PU�X9"M+��Jg$Z�t6OC1�����ɨ�UJɪ�(�R
���I��|Fd��x�̈��0No�βd���B���z	�	E��i}B��b�j �o~����������I��$�L��*�Bѐ�I1/�b&��a��er0%J
>SXL����!����!jp!�������ʧ�5�����Vs%~|�[��o}��L��C�6���I1�#�k����d|Ec�'ަ��NA� �.	���nk�RM�+J��r�J�'4�B�#t�Wd"������n�[z�f�
K�kY����rxɲx��x�V�*���bA��.T:ϫ�������=C�ꭢۗ i-ܤf-Dw�tl9�!�ΓYz�W�JkmE�(:Rq�9�O�C�~.����ɶ��Üǖl���I�C� �K}�B�����������<~�m��7;�R���\A�<��>_f+�Yx��DA���ݬ����(���F��3��e2��q��R���gF�U�ٖ��I\�-����nލ��КH:�gu+4�*z�����f�X)�6�ް٩���]m��v�i�-tGu4j[o3�Ԑ{�6<�\�ey��PB�v{lO��˱]�
����}'?�����St�i ?�H��|���
�0o�0�┋���ˡ�W�h8��v;	]�pJ�%�~��]���z���y^�~��r�y����
�+pMŹEV�Cs�4R�{�H`0�H���:��}�ٰx�8Oz�ߣw���P���3��0��<��C~�ŵ�17����E[�|��L8�(���E��4��>�J��O
o	���ЇKJ���Dg��m+<%fU�@۶�`a�D�ؠ�� ���\�g
Ѕ2�%�':��ِ��~�/�L_���9�lQ
�ݲg�xz,�m���������� ��<y�����n��ᅿ����|9�X�
���v'b�3�]�GM}��p֎�<:.�}P���og�aX�@M�n�\��y��p�U�M�qq}m8���F��xtp!��F^�j��K&����v�F3�>�D�"�8�f��N�8ɿn>2����D��\?��!�
.�`F#˳7M�;h��l@��-Ch���V�w\k�3؏���i&8�=�e(*����i&��!���0A0�=�9J�0� ��&��fLx�}Op`�9aX|s�?�\�kƂ	LY�o�W�?ń��E@g<�Gg������?R����+.�'b-O�<u4( R�� �
֑��( �� [�	�!tLP�����D�4=�����8��틋���?������#��T�.�Է0.���>�j�;@���b�i���Sײ��W<�-����V4e��ШX��U�Klp��	�xd�z����C1}�qy4�7����_,\��������}��K��H7��q�����Gi �ﯘ�>��]K{P�i|P�O>��b|X���Qh
��wf�-mi9���� ��tv۝�vv Ri����L����>��S45�v����5��/ps�>���p�NR��ŀ\~_-bkUJzF�K���ȋ������"��Z��&�K���,յE1�?%�l�oN�V(�Hs!m�F.�V�d����	��1�-��J�ָd��}+E��SGBY�ot,߿�6׷���KV�Ƿt���ʱ�%f�Y����N�=��d�\�:q���t��S���� Rj�A4�� �x�DG�X�^h��������*�j8
JU]h������lzڟV	�P{�������[@N�؇���1�ee����J�Ԭ7͝xi�,o��A[�8l4|製[�Py�XVm��+�p��|/��Ӱ�liX6Kl�]R�L��ݍ����>�VֆTl��0D��5wi3��𞜙;�p�+Fׅ��������/�z9[��T���c��?�
��|]�hm��}�e���%���C�<��2��D_��3#�ܢ��;;�
��, �^�S�ɽ���ܢk��q���_�r�6j��o��:%:F�l�'��*��>�R�Ӯ������I$qұ�#��(�,Cb�Μ�AU*��d?_% ��_�d0��`0��`0��`0�'�_Ep�s 0 