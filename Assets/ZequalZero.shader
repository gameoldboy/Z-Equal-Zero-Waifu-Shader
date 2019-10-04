Shader "CH's/ZequalZero"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
		_Flat ("Flat", Range(0, 1)) = 0
		_ToonSmooth ("Toon Smooth", Range(0, 1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			Tags {"LightMode"="ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
				float3 normal : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
			float _Flat;
			float _ToonSmooth;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
				o.normal = v.normal;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
				float3 normal = i.normal;
				normal.z*=1+pow(_Flat,4)*511;
				normal = normalize(UnityObjectToWorldNormal(normal));
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				float NdotL = max(0,dot(normal,lightDir));
				float toon = smoothstep(0, _ToonSmooth,NdotL);
				float3 ambient = ShadeSH9(half4(i.worldNormal,1));
                float shadow = SHADOW_ATTENUATION(i);
                shadow = smoothstep(0, _ToonSmooth,shadow);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(col.rgb*(ambient + toon*_LightColor0*shadow),col.a);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
