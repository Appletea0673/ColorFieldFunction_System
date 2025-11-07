Shader "Appletea's Shader/GPUEmittion v3.3"
{
	Properties
	{
		[Header(Texture)]
		_MainTex("Texture", 2D) = "white" {}
		[Space(10)]
		
		[Header(SoftParticle)]
		[Toggle]_SoftParticles("Toggle Soft Particles", Float) = 0.0
		_SoftParticlesNearFadeDistance("Soft Particles Near Fade", Range(0, 10)) = 0.0
        _SoftParticlesFarFadeDistance("Soft Particles Far Fade", Range(0,10)) = 1.0
		[Space(10)]
		
		[Header(Color Field Function Settings)]
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
			#pragma shader_feature _SOFTPARTICLES_ON
			
			#include "UnityCG.cginc"
			#include "ColorFieldFunction.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
				
				// GPU Instancing処理
                UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 vertex : POSITION;
				fixed4 color : COLOR;
				float2 uv : TEXCOORD0;
				
				#ifdef _SOFTPARTICLES_ON
                    float4 projPos :TEXCOORD2;
                #endif
				
				CFF_POS_COORDS(1)
				
				// Single Path Stereo処理
				UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
			};
			
			
			v2f vert(appdata v)
			{
				v2f o;
				// Single Path Stereo and GPU Instancing処理
                UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
                
				o.vertex = UnityObjectToClipPos(v.vertex);
				#ifdef _SOFTPARTICLES_ON
                    o.projPos = ComputeScreenPos(o.vertex);
                    COMPUTE_EYEDEPTH(o.projPos.z);
                #endif
				o.color = v.color;
				o.uv = v.uv;
				
				CFF_TRANSFER_POS(o)
				return o;
			}
			
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
			uniform float _SoftParticlesNearFadeDistance;
			uniform float _SoftParticlesFarFadeDistance;
			
			CFF_PARAM_DECLARATION

			fixed4 frag(v2f i) : SV_Target
			{
                UNITY_SETUP_INSTANCE_ID(i);
				
				float4 color = i.color;
				
				COLOR_FIELD_FUNCTION(color);
				
				#ifdef _SOFTPARTICLES_ON
					if (_SoftParticlesNearFadeDistance > 0.0 || _SoftParticlesFarFadeDistance > 0.0)
					{
						float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
						float softParticlesFade = saturate (_SoftParticlesFarFadeDistance * ((sceneZ - _SoftParticlesNearFadeDistance) - i.projPos.z));
						color.a *= softParticlesFade;
					}
                #endif
				
				return tex2D(_MainTex, i.uv) * color * i.color;
			}
			ENDCG
		}
	}
}
