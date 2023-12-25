﻿Shader "Appletea's Shader/GPUEmittion v3.0"
{
	Properties
	{
		[Header(Texture)]
		_MainTex("Texture", 2D) = "white" {}
		[Space(10)]
		
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
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent+2" "PreviewType" = "Plane" }
		LOD 100
		Cull Off
		Blend SrcAlpha One
		ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			
			#include "UnityCG.cginc"
			#include "ColorFieldFunction.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
				//GPU Instancing処理
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
				float4 pos :TEXCOORD1;
				//Single Path Stereo処理
                UNITY_VERTEX_OUTPUT_STEREO
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			v2f vert(appdata v)
			{
				v2f o;
				//Single Path Stereo and GPU Instancing処理
                UNITY_SETUP_INSTANCE_ID(v);
				#ifdef SOFTPARTICLES_ON
                    o.projPos = ComputeScreenPos(o.vertex);
                    COMPUTE_EYEDEPTH(o.projPos.z);
                #endif
                UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.color = v.color;
				o.uv = v.uv;
				o.pos = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			//GPUInstancing用パラメータ
			UNITY_INSTANCING_BUFFER_START(Props)
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

			fixed4 frag(v2f i) : SV_Target
			{
				// setup instance id to be accessed
                UNITY_SETUP_INSTANCE_ID(i);
				
				float4 color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);
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
				
				//			Field Function 演算区画					//
				//Active ColorとPassive ColorをFieldfunctionを使って線形補完
				color = ColorFieldFunction(color, PassiveColor, i.pos - CenterPosition, _rot, width, flatMode, dotMode, Shape, interval, Mode, speed, waveFreq, mShift);
				
				return tex2D(_MainTex, i.uv) * color * i.color;
			}
			ENDCG
		}
	}
}
