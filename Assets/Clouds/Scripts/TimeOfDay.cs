using UnityEngine;

[ExecuteInEditMode]

public class TimeOfDay : MonoBehaviour
{
    public float intensityMultiplier = 1f;
    public Color lightColor = Color.white;
    public Color ambientLightColor = Color.white;
    public Color fogColour = Color.white;

    public Light mainLight;

    public AnimationCurve lightRaysVolume;
    [Range(0f,0.2f)] public float lightRaysVolumeMultiplier = 0.1f;

    public Color baseSkyColour;

    public Color baseGroundColour;

    [Range(0f, 24f)]
    public float startTimeOfDay;
    [Range(0f, 24f)]
    public float timeOfDay;

    private float dawnTime = 0f;
    private float duskTime = 24f;
    [Tooltip("How long a day should last for in second. useLengthOfDaySeconds must be true.")]

    public bool progressTime = true;
    public float lengthOfDayCycleSeconds = 100f;
    [Tooltip("If false, control the Time Factor directly. Time Factor of 1 = 1 game hour per second.")]
    public bool useLengthOfDaySeconds;
    public float timeFactor = 1f;
    public Gradient lightColourByTime;
    public Gradient ambientColourByTime;
    public Gradient fogColourByTime;

    private Transform thisTransform;

    public bool updateColourByTime = true;

    // Use this for initialization
    private void Awake()
    {
        thisTransform = this.transform;
        timeOfDay = startTimeOfDay;
    }

    public float ambientLightMultiplier = 1f;
    public bool fadeShadowStrength = true;

	// Update is called once per frame
    private void Update()
    {
        if (useLengthOfDaySeconds) timeFactor = 24f / lengthOfDayCycleSeconds;
        float dayTime = 0f;



            if (progressTime && Application.isPlaying)
            {
                timeOfDay += timeFactor * Time.deltaTime;
                if (timeOfDay >= 24.0f)
                {
                    timeOfDay -= 24.0f;
                }
            }

            dayTime = Mathf.Clamp(timeOfDay, dawnTime, duskTime);
        
        float mainLightRotation = Remap(dayTime,dawnTime, duskTime, -180f, 180f);

        thisTransform.localRotation = Quaternion.Euler(thisTransform.localEulerAngles.x,
        thisTransform.localEulerAngles.y, mainLightRotation);

        float gradientSampler = Remap(dayTime,dawnTime, duskTime, 0f, 1f);

        if(fadeShadowStrength)
            mainLight.shadowStrength = lightRaysVolume.Evaluate(gradientSampler);


        if (updateColourByTime)
        {
            lightColor = lightColourByTime.Evaluate(gradientSampler);
            ambientLightColor = ambientColourByTime.Evaluate(gradientSampler)*ambientLightMultiplier;
            fogColour = fogColourByTime.Evaluate(gradientSampler);
        }

        RenderSettings.ambientSkyColor = ambientLightColor * baseSkyColour;
        RenderSettings.ambientGroundColor = baseGroundColour * ambientLightColor * ambientLightMultiplier; // * lightColor.a
        RenderSettings.fogColor = ambientLightColor * ambientLightColor.a;// * lightColor.a;

        mainLight.color = lightColor;

        mainLight.intensity = lightColor.a * intensityMultiplier;


    }


    public float Remap(float value, float from1, float to1, float from2, float to2)
    {
        return (value - from1) / (to1 - from1) * (to2 - from2) + from2;
    }


}
