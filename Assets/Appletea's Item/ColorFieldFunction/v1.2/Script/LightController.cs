using System;
using UdonSharp;
using UnityEngine;
using UnityEngine.UI;
using VRC.SDK3.Components;
using VRC.SDKBase;
using VRC.Udon;

public class LightController : UdonSharpBehaviour
{
    [Header("Colors")]
    [Space(10)]
    [SerializeField] private Color ActiveColor = Color.white;
    [SerializeField] private Color PassiveColor = Color.white;

    [Header("Common Option")]
    [Tooltip("Center Position to function")]
    [SerializeField] private Vector3 CenterPosition = new Vector3();
    [Tooltip("Effect Angle to function")]
    [SerializeField] private Vector3 Effect_Angle = new Vector3();
    [Tooltip("Width to function (Sigma)")]
    [Range(0.00001f, 10)]
    [SerializeField] private float Width = 1;
    [Tooltip("Toggle 2D Mode")]
    [SerializeField] private bool _2DMode = false;
    [Tooltip("Toggle dot Mode")]
    [SerializeField] private bool DotMode = false;
    [Tooltip("Field function type 0:Gaussian 1:Wavelet 2:Gradient")]
    [Range(0, 2)]
    [SerializeField] private int Function = 1;
    [Tooltip("Wavelet Frequency to wavelet function")]
    [Range(0.001f, 100)]
    [SerializeField] private float Wave_Frequency = 1;

    [Header("Lighting Mode")]
    [Tooltip("Toggle OneShot Mode")]
    [Space(10)]
    [SerializeField] private bool OneShotMode = false;
    

    [Header("Continuous Mode")]
    [SerializeField] private float Slide_Speed = 1;
    
    [Range(0.001f, 10)]
    [SerializeField] private float Interval = 1;

    [Header("OneShot Mode")]
    [Tooltip("Manual Shift")]
    [SerializeField] private float Manual_Shift = 1;

    
    [Header("Scene Change")]
    [Tooltip("Toggle SceneChanger")]
    [Space(20)]
    [SerializeField] private bool SceneChangerEnable;
    [Tooltip("SceneChanger Script")]
    [SerializeField] private SceneChanger scenechanger;
    [Tooltip("Next LightController Object")]
    [SerializeField] private LightController LightController_Next;
    [Tooltip("Linear Interpolation Type 0:None 1:FadeIn 2:FadeOut 3:Linear Interpolation")]
    [Range(0, 3)]
    [SerializeField] private int InterpolationType = 0;
    [Tooltip("Fade Time (Seconds)")]
    [Range(0, 120)]
    [SerializeField] private float FadeTime = 0;

    private Material[] _sharedMaterials;
    private Light[] _lights;

    //SceneChangerへパラメータを渡す関数
    public void ParameterShare(out Color _ActiveColor, out Color _PassiveColor, out Vector3 _CenterPosition, out Vector3 _Rotation, out float _Sigma, out float _Wave_Frequency, out float _Interval, out float _Manual_Shift)
    {
        _ActiveColor = ActiveColor;
        _PassiveColor = PassiveColor;
        _CenterPosition = CenterPosition;
        _Rotation = Effect_Angle;
        _Sigma = Width;
        _Wave_Frequency = Wave_Frequency;
        _Interval = Interval;
        _Manual_Shift = Manual_Shift;
    }

    private void OnEnable()
    {
        // ↓Awakeに入れたら壊れた。何故？
        // 1つ上の階層にあるObjectContainerを取ってくる
        ObjectContainer OC = this.gameObject.GetComponentInParent<ObjectContainer>();
        // GetterでContainerからデータを取得
        _sharedMaterials = OC.GetMeshRendererObject.sharedMaterials;
        // _lights = OC.GetLights;

        bool EnableSceneChanger = SceneChangerEnable && InterpolationType == 1 && scenechanger != null;

        // CFFシステム全体の座標を変えた際にCenterPositionを変えないようにするOffset
        Vector3 OffsetPos = this.transform.position;

        for (int i = 0; i < _sharedMaterials.Length; i++)
        {
            Material m = _sharedMaterials[i];
            if (!EnableSceneChanger)// SceneChanger内で処理するものを除外
            {
                m.SetColor("_ACTIVECOLOR", ActiveColor);
                m.SetColor("_PASSIVECOLOR", PassiveColor);
                m.SetVector("_CENTERPOSITION", new Vector4(CenterPosition.x + OffsetPos.x, CenterPosition.y + OffsetPos.y, CenterPosition.z + OffsetPos.z, 0));
                m.SetVector("_EFFECTROTATION", new Vector4(Effect_Angle.x, Effect_Angle.y, Effect_Angle.z, 0));
                m.SetFloat("_WIDTHTOFUNCTION", Width);
                m.SetFloat("_WAVELETFREQ", Wave_Frequency);
                m.SetFloat("_INTERVALTOFUNCTION", Interval);
                m.SetFloat("_MANUALSHIFT", Manual_Shift);
            }

            m.SetFloat("_SLIDESPEED", Slide_Speed);

            if (_2DMode) { m.EnableKeyword("_FLATMODE"); }
            if (DotMode) { m.EnableKeyword("_DOTMODE"); }
            if (OneShotMode) { m.EnableKeyword("_ONESHOTMODE"); }
            if (OneShotMode) { m.EnableKeyword("_ONESHOTMODE"); }
            switch(Function)
            {
                case 0:
                    m.EnableKeyword("_SHAPE_GAUSSIAN");
                    break;
                case 1:
                    m.EnableKeyword("_SHAPE_WAVELET");
                    break;
                case 2:
                    m.EnableKeyword("_SHAPE_GRADIENT");
                    break;
            }

        }
        /*for (int i = 0; i < _lights.Length; i++)
        {
            _lights[i].GetComponent<Light>().color = ActiveColor;
        }*/

        // SceneChanger起動
        if (EnableSceneChanger)
        {
            scenechanger.gameObject.SetActive(true);
            scenechanger.CallSceneChange(FadeTime, InterpolationType, this.GetComponent<LightController>(), LightController_Next, _sharedMaterials);
            return;
        }
    }
    private void OnDisable()
    {
        // SceneChanger起動
        if (SceneChangerEnable && (InterpolationType == 2 || InterpolationType == 3) && scenechanger != null)
        {
            // Debug.Log("Trough");
            scenechanger.gameObject.SetActive(true);
            scenechanger.CallSceneChange(FadeTime, InterpolationType, this.GetComponent<LightController>(), LightController_Next, _sharedMaterials);
        }
    }
}
