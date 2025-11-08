Shader "Appletea's Shader/MeshGPUParticle v3.3"
{
	Properties
	{
		[Header(Particle Settings)]
		_Size("Particle Size", Float) = 1.0
		[Space(20)]
		
		[Header(Color Field Function Settings)]
		[Toggle(_ENABLE_CFF)] _Enable_CFF("Enable Color Field Function", Float) = 1
		[Space(10)]
		[Header(Colors)]
		[HDR]_ACTIVECOLOR ("Active Color", Color) = (1, 1, 1, 1)
		[HDR]_PASSIVECOLOR ("Passive Color", Color) = (1, 1, 1, 1)
		[Space(10)]

		[Header(Common Option)]
		[Vector3] _CENTERPOSITION ("Center Position to function", Vector) = (0, 0, 0)
		[Vector3] _EFFECTROTATION ("Effect Angle to function", Vector) = (0, 0, 0)
		[PowerSlider(10)]
		_WIDTHTOFUNCTION ("Width to function", Range(0.00001, 10)) = 1
		[Toggle(_FLATMODE)] _flatMode("Toggle 2D Mode", Float) = 0
		[Toggle(_DOTMODE)] _dotMode("Toggle dot Mode", Float) = 0
		[KeywordEnum(Gaussian, Wavelet, Gradient)]
		_shape ("Field function type", Float) = 0
		_WAVELETFREQ ("Wavelet Freqency to wavelet function" , Range(0.001, 100)) = 1

		[Space(10)]

		[Header(Lighting Mode)]
		[Toggle(_ONESHOTMODE)] _OneShotMode("Toggle OneShot Mode", Float) = 0
		[Header(Continuous Mode)]
		_SLIDESPEED ("Slide Speed", Float) = 1
		_INTERVALTOFUNCTION ("Interval to function", Range(0.001, 10)) = 1
		[Header(OneShot Mode)]
		_MANUALSHIFT ("Manual Shift", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 100
		Cull Off
		Blend SrcAlpha One
		ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma multi_compile_instancing
			
			#include "UnityCG.cginc"
			#include "ColorFieldFunction.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				//GPU Instancing処理
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2g {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				//Single Path Stereo処理
				UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 color : TEXCOORD1;
				float d : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			float rand(float2 co) {
				return frac(sin(dot(co.xy, float2(12.9898,78.233))) * 43758.5453);
			}

			v2g vert(appdata v)
			{
				v2g o;
				//Single Path Stereo and GPU Instancing処理
                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                
				o.vertex = v.vertex;
				o.uv = v.uv.xy;
				return o;
			}
			
			
			uniform float _Size;
			uniform float4 _Color;

			CFF_PARAM_DECLARATION
			
			[maxvertexcount(4)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> stream) {

				g2f o;
				// set all values in the g2f o to 0.0
                UNITY_INITIALIZE_OUTPUT(g2f, o);
 
                // setup the instanced id to be accessed
                UNITY_SETUP_INSTANCE_ID(IN[0]);
 
                // copy instance id in the v2f IN[0] to the g2f o
                UNITY_TRANSFER_INSTANCE_ID(IN[0], o);
				
				float size = _Size;
				o.color = _Color;
				float3 cpos = (IN[0].vertex.xyz + IN[1].vertex.xyz + IN[2].vertex.xyz) / 3;

				float3 worldpos = mul(unity_ObjectToWorld, float4(cpos, 1));
				COLOR_FIELD_FUNCTION_MANUAL_POS(o.color, worldpos)
				
				float4 vp = UnityObjectToClipPos(float4(cpos, 1));
				float2 vd = vp.xy / vp.w;
				float aspectRatio = -UNITY_MATRIX_P[0][0] / UNITY_MATRIX_P[1][1];
				vd.x /= aspectRatio;
				o.d = length(vd);
				if (length(vd) < 0.0001) vd = float2(1,0);
				else vd = normalize(vd);
				float2 vn = vd.yx * float2(-1,1);

				size *= 2;
				if (abs(UNITY_MATRIX_P[0][2]) < 0.01) size *= 2;
				float sz = 0.002 * size;
				vd *= sz, vn *= sz;
				vd.x *= aspectRatio, vn.x *= aspectRatio;

				o.uv = float2(-1,-1);
				o.vertex = vp + float4(vd + vn,0,0);
				stream.Append(o);
				o.uv = float2(-1,1);
				o.vertex = vp + float4(vd - vn,0,0);
				stream.Append(o);
				o.uv = float2(1,-1);
				o.vertex = vp + float4(-vd + vn,0,0);
				stream.Append(o);
				o.uv = float2(1,1);
				o.vertex = vp + float4(-vd - vn,0,0);
				stream.Append(o);
				stream.RestartStrip();
			}

			fixed4 frag(g2f i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(i);
				
				float3 cp = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;
				
				float l = length(i.uv);
				clip(1 - l);
				float4 color = i.color;
				color.rgb *= pow(max(0, 0.5 - i.d) + 1 - l, 0.5) * 2;
				color.rgb = min(1, color);
				color.rgb = pow(color, 2.2);
				
				return float4(color.rgb,smoothstep(1,0.8,l) * color.a);
			}
			ENDCG
		}
	}
}
