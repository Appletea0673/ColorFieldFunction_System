Shader "Appletea's Shader/MeshGPUParticle v3.2"
{
	Properties
	{
		[Header(Particle Settings)]
		_Size("Particle Size", Float) = 1.0
		[Space(20)]
		
		[Header(Color Field Function Settings)]
		[Space(10)]
		[Header(Colors)]
		[HDR]_Color("Active Color", Color) = (1,1,1,1)
		[HDR]_PassiveColor("Passive Color", Color) = (1,1,1,1)
		[Space(10)]
		
		[Header(Common Option)]
		_CenterPosition("Center Position to function", Vector) = (0, 0, 0, 0)
		_Rotation("Effect Angle to function", Vector) = (0, 0, 0, 0)
		[PowerSlider(10)]
		_Width("Width to function", Range(0.00001, 10)) = 1
		[Toggle] _flatMode("Toggle 2D Mode", Float) = 0
		[Toggle] _dotMode("Toggle dot Mode", Float) = 0
		[Enum(Gaussian,0,Wavelet,1,Gradient,2)]
		_Shape("Field function type", Float) = 0
		_waveFreq("Wavelet Freqency to wavelet function" , Range(0.001, 100)) = 1

		[Space(10)]
		
		[Header(Lighting Mode)]
		[Toggle] _Mode("Toggle OneShot Mode", Float) = 0
		[Header(Continuous Mode)]
		_Speed("Slide Speed", Float) = 1
		_Interval("Interval to function", Range(0.001, 10)) = 1
		[Header(OneShot Mode)]
		_mShift("Manual Shift", Float) = 0
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
			
			
			//GPUInstancing用パラメータ
			UNITY_INSTANCING_BUFFER_START(Props)
                UNITY_DEFINE_INSTANCED_PROP(float, _Size)
                UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
                UNITY_DEFINE_INSTANCED_PROP(float4, _PassiveColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _CenterPosition)
				UNITY_DEFINE_INSTANCED_PROP(float4, _Rotation)
				UNITY_DEFINE_INSTANCED_PROP(float, _mShift)
				UNITY_DEFINE_INSTANCED_PROP(float, _Width)
				UNITY_DEFINE_INSTANCED_PROP(float, _flatMode)
				UNITY_DEFINE_INSTANCED_PROP(float, _dotMode)
				UNITY_DEFINE_INSTANCED_PROP(float, _Shape)
				UNITY_DEFINE_INSTANCED_PROP(float, _Interval)
				UNITY_DEFINE_INSTANCED_PROP(float, _Mode)
				UNITY_DEFINE_INSTANCED_PROP(float, _Speed)
				UNITY_DEFINE_INSTANCED_PROP(float, _waveFreq)
            UNITY_INSTANCING_BUFFER_END(Props)

			[maxvertexcount(4)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> stream) {

				g2f o;
				// set all values in the g2f o to 0.0
                UNITY_INITIALIZE_OUTPUT(g2f, o);
 
                // setup the instanced id to be accessed
                UNITY_SETUP_INSTANCE_ID(IN[0]);
 
                // copy instance id in the v2f IN[0] to the g2f o
                UNITY_TRANSFER_INSTANCE_ID(IN[0], o);
				
				//変数の入力
				float size = UNITY_ACCESS_INSTANCED_PROP(Props, _Size);
				o.color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
				float4 PassiveColor = UNITY_ACCESS_INSTANCED_PROP(Props, _PassiveColor);
				float3 CenterPosition = UNITY_ACCESS_INSTANCED_PROP(Props, _CenterPosition).xyz;
				float3 _rot = UNITY_ACCESS_INSTANCED_PROP(Props, _Rotation).xyz;
				float width = UNITY_ACCESS_INSTANCED_PROP(Props, _Width);
				float flatMode = UNITY_ACCESS_INSTANCED_PROP(Props, _flatMode);
				float dotMode = UNITY_ACCESS_INSTANCED_PROP(Props, _dotMode);
				float Shape = UNITY_ACCESS_INSTANCED_PROP(Props, _Shape);
				float waveFreq = UNITY_ACCESS_INSTANCED_PROP(Props, _waveFreq);
				float Mode = UNITY_ACCESS_INSTANCED_PROP(Props, _Mode);
				float speed = UNITY_ACCESS_INSTANCED_PROP(Props, _Speed);
				float interval = UNITY_ACCESS_INSTANCED_PROP(Props, _Interval);
				float mShift = UNITY_ACCESS_INSTANCED_PROP(Props, _mShift);
				float3 cpos = (IN[0].vertex.xyz + IN[1].vertex.xyz + IN[2].vertex.xyz) / 3;//3つの頂点の中心座標

				//			Field Function 演算区画					//
				float3 worldpos = mul(unity_ObjectToWorld, float4(cpos, 1));//Field function入力用World座標
				//Active ColorとPassive ColorをFieldfunctionを使って線形補完
				o.color = ColorFieldFunction(o.color, PassiveColor, worldpos - CenterPosition, _rot, width, flatMode, dotMode, Shape, interval, Mode, speed, waveFreq, mShift);

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
				//Single Path Stereo and GPU Instancing処理
                UNITY_SETUP_INSTANCE_ID(i);
				
				float3 cp = mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz;//Objectのセンターポイントを取得
				
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
