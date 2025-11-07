#ifndef COLOR_FIELD_FUNCTION_CGINC
#define COLOR_FIELD_FUNCTION_CGINC

#pragma multi_compile _ _FLATMODE
#pragma multi_compile _ _DOTMODE
#pragma multi_compile _ _ONESHOTMODE
#pragma multi_compile _SHAPE_GAUSSIAN _SHAPE_WAVELET _SHAPE_GRADIENT

// Rotate Function
inline float2 rot_FORCOLORFIELDFUNCTION(float2 p, float a) { return float2(p.x * cos(a) - p.y * sin(a), p.x * sin(a) + p.y * cos(a)); }	
inline float mod_FORCOLORFIELDFUNCTION(float y, float x) { return y - floor(y / x) * x; }

inline float Gaussian(float r, float delta)
{
	return exp(-(pow(r, 2) / (2 * delta)));
}
			
inline float Wavelet(float r, float delta, float freq)
{
	float omega = 2 * UNITY_PI * freq;
	return saturate(cos(omega * r) * exp(-(pow(r, 2) / (2 * delta))));
}
			
inline float Gradient(float3 p)
{
	// clampÇ≈-1Å`1ÇÃîÕàÕÇêÿÇËéÊÇËÅAê≥ãKâªÇ∑ÇÈ
	return (clamp(p.x, -1, 1) + 1) / 2;
}
			
			
float ContinuousWrapper(float3 p, float shift, float delta, float interval, float freq)
{	
	// FWHM(1.2î{)
	// îºílëSïùÇÃ1.2î{íˆìxÇ∏ÇÁÇ∑Ç∆èdï°Ç™ãNÇ´Ç»Ç¢èÛë‘Ç©ÇÁÉVÉtÉgÇ™â¬î\Ç≈Ç∑ÅB
	// float FWHM = 1.2 * 2.35 * sqrt(delta);
	// interval += FWHM;
	
	#ifdef _SHAPE_GAUSSIAN
		return Gaussian(mod_FORCOLORFIELDFUNCTION((length(p) - shift), 2 * interval) - interval, delta);
	#elif _SHAPE_WAVELET
		return Wavelet(mod_FORCOLORFIELDFUNCTION((length(p) - shift), 2 * interval) - interval, delta, freq);
	#elif _SHAPE_GRADIENT
		return Gradient(mod_FORCOLORFIELDFUNCTION(p / delta - shift.xxx, 2 * interval) - interval);
	#endif
}
			
float OneshotWrapper(float3 p, float delta, float freq, float mShift)
{
	#ifdef _SHAPE_GAUSSIAN
		return Gaussian(length(p) - mShift, delta);
	#elif _SHAPE_WAVELET
		return Wavelet(length(p) - mShift, delta, freq);
	#elif _SHAPE_GRADIENT
		Gradient(p / delta - mShift.xxx);
	#endif
}


// äeField FuctionÇ…ëŒÇµÇƒêßå‰Çó^Ç¶ÇÈ
float Fieldfunction(float3 p, float3 angle, float dispersion, float interval, float speed, float waveFreq, float mShift)
{
	// 2D Option
	#ifdef _FLATMODE
		p = float3(p.xy, 0);
	#endif
				
	// å¯â ÇÃâÒì]
	angle = UNITY_PI * angle / 180;
	p.yz = rot_FORCOLORFIELDFUNCTION(p.yz, angle.x);
	p.zx = rot_FORCOLORFIELDFUNCTION(p.zx, angle.y);
	p.xy = rot_FORCOLORFIELDFUNCTION(p.xy, angle.z);
				
	// îgå`ÇÃï™éUíl:dispersion
				
	// îgå`ÇÃé¸îgêî:waveFreq
					
	// îgå`ä‘ÇÃãóó£:interval
				
	float parameter = 0;
	
	#ifdef _ONESHOTMODE
		parameter = OneshotWrapper(p, dispersion, waveFreq, mShift);
	#else
		parameter = ContinuousWrapper(p, speed * _Time.y, dispersion, interval, waveFreq);
	#endif
				
	// 2bit Option
	#ifdef _DOTMODE
		parameter = step(0.5, parameter);
	#endif
	
	return parameter;
}

float4 ColorFieldFunction(float4 activecolor, float4 passivecolor, float3 pos, float3 angle, float width, float interval, float speed, float wavefreq, float mshift)
{
	return lerp(activecolor, passivecolor, Fieldfunction(pos, angle, width, interval, speed, wavefreq, mshift));
}


// Macro

#define CFF_POS_COORDS(idx) float3 CFF_POS : TEXCOORD##idx;

#define CFF_TRANSFER_POS(o) o.CFF_POS = mul(unity_ObjectToWorld, v.vertex);

#define CFF_PARAM_DECLARATION UNITY_INSTANCING_BUFFER_START(Props)\
    UNITY_DEFINE_INSTANCED_PROP(float4, _ACTIVECOLOR)\
    UNITY_DEFINE_INSTANCED_PROP(float4, _PASSIVECOLOR)\
    UNITY_DEFINE_INSTANCED_PROP(float3, _CENTERPOSITION)\
	UNITY_DEFINE_INSTANCED_PROP(float3, _EFFECTROTATION)\
	UNITY_DEFINE_INSTANCED_PROP(float, _WIDTHTOFUNCTION)\
	UNITY_DEFINE_INSTANCED_PROP(float, _INTERVALTOFUNCTION)\
	UNITY_DEFINE_INSTANCED_PROP(float, _WAVELETFREQ)\
	UNITY_DEFINE_INSTANCED_PROP(float, _SLIDESPEED)\
	UNITY_DEFINE_INSTANCED_PROP(float, _MANUALSHIFT)\
UNITY_INSTANCING_BUFFER_END(Props)

#define CFF_CALL_PARAMETER float4 ACTIVECOLOR = UNITY_ACCESS_INSTANCED_PROP(Props, _ACTIVECOLOR);\
	float4 PASSIVECOLOR = UNITY_ACCESS_INSTANCED_PROP(Props, _PASSIVECOLOR);\
	float3 CENTERPOSITION = UNITY_ACCESS_INSTANCED_PROP(Props, _CENTERPOSITION);\
	float3 EFFECTROTATION = UNITY_ACCESS_INSTANCED_PROP(Props, _EFFECTROTATION);\
	float WIDTHTOFUNCTION = UNITY_ACCESS_INSTANCED_PROP(Props, _WIDTHTOFUNCTION);\
	float INTERVALTOFUNCTION = UNITY_ACCESS_INSTANCED_PROP(Props, _INTERVALTOFUNCTION);\
	float SLIDESPEED = UNITY_ACCESS_INSTANCED_PROP(Props, _SLIDESPEED);\
	float WAVELETFREQ = UNITY_ACCESS_INSTANCED_PROP(Props, _WAVELETFREQ);\
	float MANUALSHIFT = UNITY_ACCESS_INSTANCED_PROP(Props, _MANUALSHIFT);

#define COLOR_FIELD_FUNCTION(color) CFF_CALL_PARAMETER\
	color = ColorFieldFunction(ACTIVECOLOR * color, PASSIVECOLOR, mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz - CENTERPOSITION, EFFECTROTATION, WIDTHTOFUNCTION, INTERVALTOFUNCTION, SLIDESPEED, WAVELETFREQ, MANUALSHIFT);


#define COLOR_FIELD_FUNCTION_VERTEX(color) CFF_CALL_PARAMETER\
	color = ColorFieldFunction(ACTIVECOLOR * color, PASSIVECOLOR, i.CFF_POS - CENTERPOSITION, EFFECTROTATION, WIDTHTOFUNCTION, INTERVALTOFUNCTION, SLIDESPEED, WAVELETFREQ, MANUALSHIFT);

#define COLOR_FIELD_FUNCTION_MANUAL_POS(color, pos) CFF_CALL_PARAMETER\
	color = ColorFieldFunction(ACTIVECOLOR * color, PASSIVECOLOR, pos - CENTERPOSITION, EFFECTROTATION, WIDTHTOFUNCTION, INTERVALTOFUNCTION, SLIDESPEED, WAVELETFREQ, MANUALSHIFT);

#endif